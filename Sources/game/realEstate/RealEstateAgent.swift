//
//  RealEstateAgent.swift
//
//
//  Created by Tomasz Kucharski on 17/03/2021.
//

import Foundation

protocol RealEstateAgentDelegate {
    func syncWalletChange(playerUUID: String)
    func notifyEveryone(_ notification: UINotification)
    func reloadMap()
}

class RealEstateAgent {
    let mapManager: GameMapManager
    let centralBank: CentralBank
    let priceList: PriceList
    let propertyValuer: PropertyValuer
    var delegate: RealEstateAgentDelegate?
    let dataStore: DataStoreProvider
    private let semaphore = DispatchSemaphore(value: 1)

    init(mapManager: GameMapManager, propertyValuer: PropertyValuer, centralBank: CentralBank, delegate: RealEstateAgentDelegate? = nil) {
        self.mapManager = mapManager
        self.propertyValuer = propertyValuer
        self.dataStore = centralBank.dataStore
        self.centralBank = centralBank
        self.delegate = delegate
        self.priceList = PriceList()
    }

    func isForSale(address: MapPoint) -> Bool {
        guard let tile = self.mapManager.map.getTile(address: address) else {
            return true
        }
        if tile.type == .cityCouncil {
            return false
        }
        if self.getProperty(address: tile.address)?.ownerUUID == SystemPlayer.government.uuid {
            return true
        }
        if let _: SaleAdvert = self.dataStore.find(address: address) {
            return true
        }
        return false
    }

    func getProperty(address: MapPoint) -> Property? {
        guard let tile = self.mapManager.map.getTile(address: address) else {
            return nil
        }
        guard let propertyType = tile.propertyType else {
            return nil
        }
        switch propertyType {
        case .land:
            let land: Land? = self.dataStore.find(address: address)
            return land
        case .road:
            let road: Road? = self.dataStore.find(address: address)
            return road
        case .parking:
            let parking: Parking? = self.dataStore.find(address: address)
            return parking
        case .residentialBuilding:
            let building: ResidentialBuilding? = self.dataStore.find(address: address)
            return building
        }
    }

    func registerSaleOffer(address: MapPoint, netValue: Double) throws {
        guard self.mapManager.map.isAddressOnMap(address) else {
            Logger.error("RealEstateAgent", "RegisterOfferError.propertyDoesNotExist \(address.description) - address is not on map")
            throw RegisterOfferError.propertyDoesNotExist
        }
        guard let propertyType = self.mapManager.map.getTile(address: address)?.propertyType else {
            Logger.error("RealEstateAgent", "RegisterOfferError.propertyDoesNotExist \(address.description) - missing tile on map")
            throw RegisterOfferError.propertyDoesNotExist
        }
        let exists: SaleAdvert? = self.dataStore.find(address: address)
        guard exists == nil else {
            Logger.error("RealEstateAgent", "RegisterOfferError.advertAlreadyExists \(address.description)")
            throw RegisterOfferError.advertAlreadyExists
        }

        let property: Property?
        switch propertyType {
        case .land:
            let land: Land? = self.dataStore.find(address: address)
            property = land
        case .road:
            let road: Road? = self.dataStore.find(address: address)
            property = road
        case .parking:
            let parking: Parking? = self.dataStore.find(address: address)
            property = parking
        case .residentialBuilding:
            let building: ResidentialBuilding? = self.dataStore.find(address: address)
            property = building
        }
        guard let property = property else {
            Logger.error("RealEstateAgent", "RegisterOfferError.propertyDoesNotExist \(address.description) - missing property instance")
            throw RegisterOfferError.propertyDoesNotExist
        }

        if let register: PropertyRegister = self.dataStore.find(uuid: property.uuid), register.status == .blockedByDebtCollector {
            Logger.error("RealEstateAgent", "RegisterOfferError.propertyBlockedByDebtCollector \(address.description)")
            throw RegisterOfferError.propertyBlockedByDebtCollector
        }

        Logger.info("RealEstateAgent", "Registered new SaleOffer @\(address.description) \(property.type) \(property.name) \(netValue.money)")
        let advert = SaleAdvert(address: property.address, netPrice: netValue)
        self.dataStore.create(advert)
    }

    func updateSaleOffer(address: MapPoint, netValue: Double) throws {
        guard let advert: SaleAdvert = self.dataStore.find(address: address) else {
            Logger.error("RealEstateAgent", "UpdateOfferError.offerDoesNotExist \(address.description)")
            throw UpdateOfferError.offerDoesNotExist
        }
        Logger.info("RealEstateAgent", "Updated SaleOffer @\(address.description) \(advert.netPrice.money) -> \(netValue.money)")
        let mutation = SaleAdvertMutation(address: address, attributes: [.netPrice(netValue)])
        self.dataStore.update(mutation)
    }

    func cancelSaleOffer(address: MapPoint) {
        self.dataStore.removeSaleAdvert(address: address)
    }

    func getAllSaleOffers(buyerUUID: String) -> [SaleOffer] {
        let adverts: [SaleAdvert] = self.dataStore.getAll()
        var offers: [SaleOffer] = []
        for advert in adverts {
            if let tile = self.mapManager.map.getTile(address: advert.address), let propertyType = tile.propertyType {
                switch propertyType {
                case .land:
                    if let offer = self.landSaleOffer(address: advert.address, buyerUUID: buyerUUID) {
                        offers.append(offer)
                    }
                case .road:
                    break
                case .parking:
                    if let offer = self.parkingSaleOffer(address: advert.address, buyerUUID: buyerUUID) {
                        offers.append(offer)
                    }
                case .residentialBuilding:
                    if let offer = self.residentialBuildingSaleOffer(address: advert.address, buyerUUID: buyerUUID) {
                        offers.append(offer)
                    }
                }
            }
        }
        return offers
    }

    func saleOffer(address: MapPoint, buyerUUID: String) -> SaleOffer? {
        guard let tile = self.mapManager.map.getTile(address: address) else {
            return self.landSaleOffer(address: address, buyerUUID: buyerUUID)
        }
        guard let propertyType = tile.propertyType else {
            return nil
        }
        switch propertyType {
        case .land:
            return self.landSaleOffer(address: address, buyerUUID: buyerUUID)
        case .road:
            return nil
        case .parking:
            return self.parkingSaleOffer(address: address, buyerUUID: buyerUUID)
        case .residentialBuilding:
            return self.residentialBuildingSaleOffer(address: address, buyerUUID: buyerUUID)
        }
    }

    private func landSaleOffer(address: MapPoint, buyerUUID: String) -> SaleOffer? {
        // if it is no one's land, it's on sale by government
        // if it is private sale the offer is in the advert list
        let tile = self.mapManager.map.getTile(address: address)

        var land: Land?
        var price: Double?
        var name = RandomNameGenerator.getName()

        if tile == nil {
            price = self.propertyValuer.estimateValue(address)
        } else {
            if let existingLand: Land = self.dataStore.find(address: address) {
                if existingLand.ownerUUID == SystemPlayer.government.uuid {
                    land = existingLand
                    name = existingLand.name
                    price = self.propertyValuer.estimateValue(address)
                } else if let advert: SaleAdvert = self.dataStore.find(address: address) {
                    land = existingLand
                    name = existingLand.name
                    price = advert.netPrice
                }
            } else {
                return nil
            }
        }
        guard let price = price else {
            return nil
        }

        var commission = self.priceList.realEstateSellLandPropertyCommisionFee + price * self.priceList.realEstateSellPropertyCommisionRate
        if commission > self.priceList.realEstateSellPropertyCommisionThreshold {
            commission = self.priceList.realEstateSellPropertyCommisionThreshold + commission / 10
        }

        let saleInvoice = Invoice(title: "Purchase land \(name)", netValue: price, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        let commissionInvoice = Invoice(title: "Commission for purchase land \(name)", grossValue: commission, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        let property = land ?? Land(address: address, name: name, purchaseNetValue: saleInvoice.netValue, investmentsNetValue: commissionInvoice.total)

        return SaleOffer(saleInvoice: saleInvoice, commissionInvoice: commissionInvoice, property: property)
    }

    private func parkingSaleOffer(address: MapPoint, buyerUUID: String) -> SaleOffer? {
        guard let advert: SaleAdvert = self.dataStore.find(address: address) else {
            return nil
        }

        guard let parking: Parking = self.dataStore.find(address: address) else {
            return nil
        }
        let price = advert.netPrice

        var commission = self.priceList.realEstateSellLandPropertyCommisionFee + price * self.priceList.realEstateSellPropertyCommisionRate
        if commission > self.priceList.realEstateSellPropertyCommisionThreshold {
            commission = self.priceList.realEstateSellPropertyCommisionThreshold + commission / 10
        }

        let saleInvoice = Invoice(title: "Purchase \(parking.name)", netValue: price, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        let commissionInvoice = Invoice(title: "Commission for purchase \(parking.name)", grossValue: commission, taxRate: self.centralBank.taxRates.propertyPurchaseTax)

        return SaleOffer(saleInvoice: saleInvoice, commissionInvoice: commissionInvoice, property: parking)
    }

    private func residentialBuildingSaleOffer(address: MapPoint, buyerUUID: String) -> SaleOffer? {
        guard let tile = self.mapManager.map.getTile(address: address), tile.isBuilding() else {
            return nil
        }
        guard let building: ResidentialBuilding = self.dataStore.find(address: address) else {
            return nil
        }
        var price: Double?
        if building.ownerUUID == SystemPlayer.government.uuid {
            price = self.propertyValuer.estimateValue(address)
        } else {
            guard let advert: SaleAdvert = self.dataStore.find(address: address) else {
                return nil
            }
            price = advert.netPrice
        }
        guard let price = price else {
            return nil
        }
        var commission = self.priceList.realEstateSellResidentialBuildingCommisionFee + price * self.priceList.realEstateSellPropertyCommisionRate
        if commission > self.priceList.realEstateSellPropertyCommisionThreshold {
            commission = self.priceList.realEstateSellPropertyCommisionThreshold + commission / 10
        }
        let saleInvoice = Invoice(title: "Purchase \(building.name)", netValue: price, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        let commissionInvoice = Invoice(title: "Commission for purchase land \(building.name)", grossValue: commission, taxRate: self.centralBank.taxRates.propertyPurchaseTax)

        return SaleOffer(saleInvoice: saleInvoice, commissionInvoice: commissionInvoice, property: building)
    }

    func buyProperty(address: MapPoint, buyerUUID: String, netPrice: Double? = nil) throws {
        guard let tile = self.mapManager.map.getTile(address: address) else {
            try self.buyLandProperty(address: address, buyerUUID: buyerUUID)
            return
        }
        guard let propertyType = tile.propertyType else {
            throw BuyPropertyError.propertyNotForSale
        }
        switch propertyType {
        case .land:
            try self.buyLandProperty(address: address, buyerUUID: buyerUUID, netPrice: netPrice)
        case .road:
            throw BuyPropertyError.propertyNotForSale
        case .parking:
            try self.buyParkingProperty(address: address, buyerUUID: buyerUUID, netPrice: netPrice)
        case .residentialBuilding:
            try self.buyResidentialBuilding(address: address, buyerUUID: buyerUUID, netPrice: netPrice)
        }
        self.dataStore.removeSaleAdvert(address: address)
    }

    private func buyLandProperty(address: MapPoint, buyerUUID: String, netPrice: Double? = nil) throws {
        self.semaphore.wait()
        guard let offer = self.landSaleOffer(address: address, buyerUUID: buyerUUID) else {
            Logger.error("RealEstateAgent", "buyLandProperty:offer not found")
            self.semaphore.signal()
            throw BuyPropertyError.propertyNotForSale
        }
        if let netPrice = netPrice {
            guard offer.saleInvoice.netValue == netPrice else {
                self.semaphore.signal()
                throw BuyPropertyError.saleOfferHasChanged
            }
        }
        guard let land = offer.property as? Land else {
            Logger.error("RealEstateAgent", "buyLandProperty:land not found")
            self.semaphore.signal()
            throw BuyPropertyError.propertyNotForSale
        }
        let sellerID = land.ownerUUID
        guard sellerID != buyerUUID else {
            Logger.error("RealEstateAgent", "buyLandProperty:seller the same as buyer")
            self.semaphore.signal()
            throw BuyPropertyError.tryingBuyOwnProperty
        }
        Logger.info("RealEstateAgent", "New land sale transaction. @\(address.description)")
        let realEstateAgentID = SystemPlayer.realEstateAgency.uuid
        // process the transaction
        let saleTransaction = FinancialTransaction(payerUUID: buyerUUID, recipientUUID: sellerID, invoice: offer.saleInvoice, type: .realEstateTrade)
        do {
            try self.centralBank.process(saleTransaction)
        } catch let error as FinancialTransactionError {
            Logger.error("RealEstateAgent", "buyLandProperty:sale invoice transaction problem")
            self.semaphore.signal()
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        let feeTransaction = FinancialTransaction(payerUUID: buyerUUID, recipientUUID: realEstateAgentID, invoice: offer.commissionInvoice, type: .services)
        do {
            try self.centralBank.process(feeTransaction)
        } catch let error as FinancialTransactionError {
            Logger.error("RealEstateAgent", "buyLandProperty:commission invoice transaction problem")
            self.semaphore.signal()
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        var landUUID = land.uuid
        if land.uuid.isEmpty {
            landUUID = self.dataStore.create(land)
            self.dataStore.update(LandMutation(uuid: landUUID, attributes: [.ownerUUID(buyerUUID), .investments(offer.commissionInvoice.total)]))
        } else {
            let costs = land.investmentsNetValue + land.purchaseNetValue
            self.centralBank.refundIncomeTax(transaction: saleTransaction, costs: costs)
            var modifications: [LandMutation.Attribute] = []
            modifications.append(.purchaseNetValue(offer.saleInvoice.netValue))
            modifications.append(.ownerUUID(buyerUUID))
            modifications.append(.investments(offer.commissionInvoice.total))
            let mutation = LandMutation(uuid: land.uuid, attributes: modifications)
            self.dataStore.update(mutation)
        }

        if let register: PropertyRegister = self.dataStore.find(uuid: landUUID) {
            let mutation = PropertyRegisterMutation(uuid: register.uuid, attributes: [.ownerUUID(buyerUUID), .type(.land), .status(.normal)])
            self.dataStore.update(mutation)
        } else {
            let register = PropertyRegister(uuid: landUUID, address: land.address, playerUUID: buyerUUID, type: .land)
            self.dataStore.create(register)
        }

        self.mapManager.addPrivateLand(address: land.address)

        self.semaphore.signal()
        self.delegate?.syncWalletChange(playerUUID: buyerUUID)
        self.delegate?.syncWalletChange(playerUUID: sellerID)
        self.delegate?.reloadMap()
        let playerName = self.dataStore.find(uuid: buyerUUID)?.login ?? ""
        self.delegate?.notifyEveryone(UINotification(text: "New transaction on the market. Player <b>\(playerName)</b> has just bought property '\(land.name)' located <i>\(land.readableAddress)</i>", level: .info, duration: 10, icon: .property))
    }

    private func buyParkingProperty(address: MapPoint, buyerUUID: String, netPrice: Double? = nil) throws {
        self.semaphore.wait()
        guard let offer = self.parkingSaleOffer(address: address, buyerUUID: buyerUUID) else {
            Logger.error("RealEstateAgent", "buyParkingProperty:offer not found")
            self.semaphore.signal()
            throw BuyPropertyError.propertyNotForSale
        }
        if let netPrice = netPrice {
            guard offer.saleInvoice.netValue == netPrice else {
                self.semaphore.signal()
                throw BuyPropertyError.saleOfferHasChanged
            }
        }
        guard let parking = offer.property as? Parking else {
            Logger.error("RealEstateAgent", "buyParkingProperty:land not found")
            self.semaphore.signal()
            throw BuyPropertyError.propertyNotForSale
        }
        try self.processBuyTransaction(offer, buyerUUID: buyerUUID)

        var modifications: [ParkingMutation.Attribute] = []
        modifications.append(.purchaseNetValue(offer.saleInvoice.netValue))
        modifications.append(.ownerUUID(buyerUUID))
        modifications.append(.investments(offer.commissionInvoice.total))
        let mutation = ParkingMutation(uuid: parking.uuid, attributes: modifications)
        self.dataStore.update(mutation)

        if let register: PropertyRegister = self.dataStore.find(uuid: parking.uuid) {
            let mutation = PropertyRegisterMutation(uuid: register.uuid, attributes: [.ownerUUID(buyerUUID), .type(.parking), .status(.normal)])
            self.dataStore.update(mutation)
        } else {
            let register = PropertyRegister(uuid: parking.uuid, address: parking.address, playerUUID: buyerUUID, type: .parking)
            self.dataStore.create(register)
        }

        self.semaphore.signal()
        self.delegate?.syncWalletChange(playerUUID: buyerUUID)
        self.delegate?.syncWalletChange(playerUUID: offer.property.ownerUUID)
        let playerName = self.dataStore.find(uuid: buyerUUID)?.login ?? ""
        self.delegate?.notifyEveryone(UINotification(text: "New transaction on the market. Player <b>\(playerName)</b> has just bought property '\(parking.name)' located <i>\(parking.readableAddress)</i>", level: .info, duration: 10, icon: .property))
    }

    private func processBuyTransaction(_ offer: SaleOffer, buyerUUID: String) throws {
        let sellerID = offer.property.ownerUUID
        guard sellerID != buyerUUID else {
            Logger.error("RealEstateAgent", "BuyPropertyError.tryingBuyOwnProperty")
            self.semaphore.signal()
            throw BuyPropertyError.tryingBuyOwnProperty
        }
        Logger.info("RealEstateAgent", "New \(type(of: offer.property)) sale transaction. @\(offer.property.address.description)")
        let realEstateAgentID = SystemPlayer.realEstateAgency.uuid
        // process the transaction
        let saleTransaction = FinancialTransaction(payerUUID: buyerUUID, recipientUUID: sellerID, invoice: offer.saleInvoice, type: .realEstateTrade)
        do {
            try self.centralBank.process(saleTransaction)
        } catch let error as FinancialTransactionError {
            Logger.error("RealEstateAgent", "BuyPropertyError.financialTransactionProblem")
            self.semaphore.signal()
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        let feeTransaction = FinancialTransaction(payerUUID: buyerUUID, recipientUUID: realEstateAgentID, invoice: offer.commissionInvoice, type: .services)
        do {
            try self.centralBank.process(feeTransaction)
        } catch let error as FinancialTransactionError {
            Logger.error("RealEstateAgent", "BuyPropertyError.financialTransactionProblem")
            self.semaphore.signal()
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        let costs = offer.property.investmentsNetValue + offer.property.purchaseNetValue
        self.centralBank.refundIncomeTax(transaction: saleTransaction, costs: costs)
    }

    private func buyResidentialBuilding(address: MapPoint, buyerUUID: String, netPrice: Double? = nil) throws {
        self.semaphore.wait()
        guard let offer = self.residentialBuildingSaleOffer(address: address, buyerUUID: buyerUUID) else {
            Logger.error("RealEstateAgent", "buyResidentialBuilding:offer not found")
            self.semaphore.signal()
            throw BuyPropertyError.propertyNotForSale
        }

        if let netPrice = netPrice {
            guard offer.saleInvoice.netValue == netPrice else {
                self.semaphore.signal()
                throw BuyPropertyError.saleOfferHasChanged
            }
        }
        guard let building = offer.property as? ResidentialBuilding else {
            Logger.error("RealEstateAgent", "buyResidentialBuilding:building not found")
            self.semaphore.signal()
            throw BuyPropertyError.propertyNotForSale
        }
        try self.processBuyTransaction(offer, buyerUUID: buyerUUID)

        var modifications: [ResidentialBuildingMutation.Attribute] = []
        modifications.append(.ownerUUID(buyerUUID))
        modifications.append(.purchaseNetValue(offer.saleInvoice.netValue))
        modifications.append(.investmentsNetValue(offer.commissionInvoice.total))
        let mutation = ResidentialBuildingMutation(uuid: building.uuid, attributes: modifications)
        self.dataStore.update(mutation)

        if let register: PropertyRegister = self.dataStore.find(uuid: building.uuid) {
            let mutation = PropertyRegisterMutation(uuid: register.uuid, attributes: [.ownerUUID(buyerUUID), .type(.residentialBuilding), .status(.normal)])
            self.dataStore.update(mutation)
        } else {
            let register = PropertyRegister(uuid: building.uuid, address: building.address, playerUUID: buyerUUID, type: .residentialBuilding)
            self.dataStore.create(register)
        }

        self.semaphore.signal()

        self.delegate?.syncWalletChange(playerUUID: buyerUUID)
        self.delegate?.syncWalletChange(playerUUID: offer.property.ownerUUID)
        let playerName = self.dataStore.find(uuid: buyerUUID)?.login ?? ""
        self.delegate?.notifyEveryone(UINotification(text: "New transaction on the market. Player <b>\(playerName)</b> has just bought property '\(building.name)' located <i>\(building.readableAddress)</i>", level: .info, duration: 10, icon: .property))
    }
}

enum BuyPropertyError: Error, Equatable {
    case propertyNotForSale
    case tryingBuyOwnProperty
    case saleOfferHasChanged
    case financialTransactionProblem(FinancialTransactionError)
}

enum RegisterOfferError: Error {
    case propertyDoesNotExist
    case advertAlreadyExists
    case propertyBlockedByDebtCollector
}

enum UpdateOfferError: Error {
    case offerDoesNotExist
}
