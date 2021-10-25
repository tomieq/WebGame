//
//  RealEstateAgent.swift
//  
//
//  Created by Tomasz Kucharski on 17/03/2021.
//

import Foundation

protocol RealEstateAgentDelegate {
    func notifyWalletChange(playerUUID: String)
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
        case .residentialBuilding:
            let building: ResidentialBuilding? = self.dataStore.find(address: address)
            return building
        }
    }

    func registerSaleOffer(address: MapPoint, netValue: Double) throws {
        guard self.mapManager.map.isAddressOnMap(address) else {
            throw RegisterOfferError.propertyDoesNotExist
        }
        guard let propertyType = self.mapManager.map.getTile(address: address)?.propertyType else {
            throw RegisterOfferError.propertyDoesNotExist
        }
        let exists: SaleAdvert? = self.dataStore.find(address: address)
        guard exists == nil else {
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
        case .residentialBuilding:
            let building: ResidentialBuilding? = self.dataStore.find(address: address)
            property = building
        }
        guard let property = property else {
            throw RegisterOfferError.propertyDoesNotExist
        }
        Logger.info("RealEstateAgent", "Registered new SaleOffer @\(address.description) \(property.type) \(property.name) \(netValue.money)")
        let advert = SaleAdvert(address: property.address, netPrice: netValue)
        self.dataStore.create(advert)
    }
    
    func updateSaleOffer(address: MapPoint, netValue: Double) throws {
        guard let advert: SaleAdvert = self.dataStore.find(address: address) else {
            throw UpdateOfferError.offerDoesNotExist
        }
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
        var name = "\(RandomNameGenerator.randomAdjective.capitalized) \(RandomNameGenerator.randomNoun.capitalized)"
        
        if tile == nil {
            price = self.propertyValuer.estimateValue(address)
        } else {
            guard let advert: SaleAdvert = self.dataStore.find(address: address),
                  let existingLand: Land = self.dataStore.find(address: address) else {
                return nil
            }
            land = existingLand
            name = existingLand.name
            price = advert.netPrice
        }
        guard let price = price else {
            return nil
        }
        
        let commission = self.priceList.realEstateSellLandPropertyCommisionFee + price * self.priceList.realEstateSellPropertyCommisionRate
        
        let saleInvoice = Invoice(title: "Purchase land \(name)", netValue: price, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        let commissionInvoice = Invoice(title: "Commission for purchase land \(name)", grossValue: commission, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        let property = land ?? Land(address: address, name: name, purchaseNetValue: saleInvoice.netValue, investmentsNetValue: commissionInvoice.total)
        
        return SaleOffer(saleInvoice: saleInvoice, commissionInvoice: commissionInvoice, property: property)
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
        let commission = self.priceList.realEstateSellResidentialBuildingCommisionFee + price * self.priceList.realEstateSellPropertyCommisionRate
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
        case .residentialBuilding:
            try self.buyResidentialBuilding(address: address, buyerUUID: buyerUUID, netPrice: netPrice)
        }
        self.dataStore.removeSaleAdvert(address: address)
    }
    
    private func buyLandProperty(address: MapPoint, buyerUUID: String, netPrice: Double? = nil) throws {
        
        guard let offer = self.landSaleOffer(address: address, buyerUUID: buyerUUID) else {
            Logger.error("RealEstateAgent", "buyLandProperty:offer not found")
            throw BuyPropertyError.propertyNotForSale
        }
        if let netPrice = netPrice {
            guard offer.saleInvoice.netValue == netPrice else {
                throw BuyPropertyError.saleOfferHasChanged
            }
        }
        guard let land = offer.property as? Land else {
            Logger.error("RealEstateAgent", "buyLandProperty:land not found")
            throw BuyPropertyError.propertyNotForSale
        }
        let sellerID = land.ownerUUID
        guard sellerID != buyerUUID else {
            Logger.error("RealEstateAgent", "buyLandProperty:seller the same as buyer")
            throw BuyPropertyError.tryingBuyOwnProperty
        }
        Logger.info("RealEstateAgent", "New land sale transaction. @\(address.description)")
        let realEstateAgentID = SystemPlayer.realEstateAgency.uuid
        // process the transaction
        let saleTransaction = FinancialTransaction(payerUUID: buyerUUID, recipientUUID: sellerID , invoice: offer.saleInvoice)
        do {
             try self.centralBank.process(saleTransaction)
        } catch let error as FinancialTransactionError {
            Logger.error("RealEstateAgent", "buyLandProperty:sale invoice transaction problem")
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        let feeTransaction = FinancialTransaction(payerUUID: buyerUUID, recipientUUID: realEstateAgentID, invoice: offer.commissionInvoice)
        do {
             try self.centralBank.process(feeTransaction)
        } catch let error as FinancialTransactionError {
            Logger.error("RealEstateAgent", "buyLandProperty:commission invoice transaction problem")
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        if land.uuid.isEmpty {
            let landUUID = self.dataStore.create(land)
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

        self.mapManager.map.replaceTile(tile: land.mapTile)
        
        self.delegate?.notifyWalletChange(playerUUID: buyerUUID)
        self.delegate?.notifyWalletChange(playerUUID: sellerID)
        self.delegate?.reloadMap()
        let playerName = self.dataStore.find(uuid: buyerUUID)?.login ?? ""
        self.delegate?.notifyEveryone(UINotification(text: "New transaction on the market. Player \(playerName) has just bought property `\(land.name)`", level: .info, duration: 10))
    }
    
    private func buyResidentialBuilding(address: MapPoint, buyerUUID: String, netPrice: Double? = nil) throws {
        
        guard let offer = self.residentialBuildingSaleOffer(address: address, buyerUUID: buyerUUID) else {
            Logger.error("RealEstateAgent", "buyResidentialBuilding:offer not found")
            throw BuyPropertyError.propertyNotForSale
        }
        
        if let netPrice = netPrice {
            guard offer.saleInvoice.netValue == netPrice else {
                throw BuyPropertyError.saleOfferHasChanged
            }
        }
        guard let building = offer.property as? ResidentialBuilding else {
            Logger.error("RealEstateAgent", "buyResidentialBuilding:building not found")
            throw BuyPropertyError.propertyNotForSale
        }
        let sellerID = building.ownerUUID
        guard sellerID != buyerUUID else {
            Logger.error("RealEstateAgent", "buyResidentialBuilding:seller the same as buyer")
            throw BuyPropertyError.tryingBuyOwnProperty
        }
        Logger.info("RealEstateAgent", "New residentialBuilding sale transaction. @\(address.description)")
        let realEstateAgentID = SystemPlayer.realEstateAgency.uuid
        // process the transaction
        let saleTransaction = FinancialTransaction(payerUUID: buyerUUID, recipientUUID: sellerID , invoice: offer.saleInvoice)
        do {
             try self.centralBank.process(saleTransaction)
        } catch let error as FinancialTransactionError {
            Logger.error("RealEstateAgent", "buyResidentialBuilding:sale invoice transaction problem")
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        let feeTransaction = FinancialTransaction(payerUUID: buyerUUID, recipientUUID: realEstateAgentID, invoice: offer.commissionInvoice)
        do {
             try self.centralBank.process(feeTransaction)
        } catch let error as FinancialTransactionError {
            Logger.error("RealEstateAgent", "buyResidentialBuilding:commission invoice transaction problem")
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        let costs = building.investmentsNetValue + building.purchaseNetValue
        self.centralBank.refundIncomeTax(transaction: saleTransaction, costs: costs)
        var modifications: [ResidentialBuildingMutation.Attribute] = []
        modifications.append(.ownerUUID(buyerUUID))
        modifications.append(.purchaseNetValue(offer.saleInvoice.netValue))
        modifications.append(.investmentsNetValue(offer.commissionInvoice.total))
        let mutation = ResidentialBuildingMutation(uuid: building.uuid, attributes: modifications)
        self.dataStore.update(mutation)
        
        self.delegate?.notifyWalletChange(playerUUID: buyerUUID)
        self.delegate?.notifyWalletChange(playerUUID: sellerID)
        let playerName = self.dataStore.find(uuid: buyerUUID)?.login ?? ""
        self.delegate?.notifyEveryone(UINotification(text: "New transaction on the market. Player \(playerName) has just bought property `\(building.name)`", level: .info, duration: 10))
    }
    
    func rentApartment(_ apartment: Apartment) {
        apartment.isRented = true
        if let building: ResidentialBuilding = self.dataStore.find(address: apartment.address) {
            self.recalculateFeesInTheBuilding(building)
        }
    }
    
    func unrentApartment(_ apartment: Apartment) {
        apartment.isRented = false
        if let building: ResidentialBuilding = self.dataStore.find(address: apartment.address) {
            self.recalculateFeesInTheBuilding(building)
        }
    }
    /*
    func estimateApartmentValue(_ apartment: Apartment) -> Double {
        if let building: ResidentialBuilding = self.dataStore.find(address: apartment.address) {
            let investmentCost = 0.0//ConstructionPriceList.makeResidentialBuildingCost(storey: building.storeyAmount)
            let numberOfFlats = Double(building.numberOfFlatsPerStorey * building.storeyAmount)
            let baseValue = (investmentCost/numberOfFlats + self.priceList.residentialBuildingOwnerIncomeOnFlatSellPrice) * 1.42
            return (baseValue * building.condition/100 * apartment.condition/100 * self.calculateLocationValueFactor(building.address)).rounded(toPlaces: 0)
        }
        Logger.error("RealEstateAgent", "Apartment \(apartment.uuid) is detached from building!")
        return 900000000
    }
    
    func estimateRentFee(_ apartment: Apartment) -> Double {
        if let building: ResidentialBuilding = self.dataStore.find(address: apartment.address) {
            return (self.priceList.monthlyApartmentRentalFee * building.condition/100 * apartment.condition/100 * self.calculateLocationValueFactor(building.address)).rounded(toPlaces: 0)
        }
        return 0.0
    }
    */
    func recalculateFeesInTheBuilding(_ building: ResidentialBuilding) {
        /*
        let baseBuildingMonthlyCosts: Double = self.priceList.montlyResidentialBuildingCost + self.priceList.montlyResidentialBuildingCostPerStorey * building.storeyAmount.double
        let numberOfFlats = Double(building.storeyAmount * building.numberOfFlatsPerStorey)
        
        let buildingCostPerFlat = (baseBuildingMonthlyCosts/numberOfFlats + self.priceList.monthlyResidentialBuildingOwnerIncomePerFlat).rounded(toPlaces: 0)
        
        var income: Double = 0
        var spendings = baseBuildingMonthlyCosts
        for apartment in Storage.shared.getApartments(address: building.address) {
            
            switch apartment.isRented {
                case true:
                apartment.monthlyRentalFee = self.estimateRentFee(apartment)
                apartment.monthlyBills = self.priceList.monthlyBillsForRentedApartment
                case false:
                apartment.monthlyRentalFee = 0
                apartment.monthlyBills = self.priceList.monthlyBillsForUnrentedApartment
            }
            
            if apartment.ownerID == building.ownerID {
                apartment.monthlyBuildingFee = 0
                income += apartment.monthlyRentalFee
                spendings += apartment.monthlyBills
            } else {
                apartment.monthlyBuildingFee = buildingCostPerFlat
                income += apartment.monthlyBuildingFee
            }
        }
        building.monthlyIncome = income.rounded(toPlaces: 0)
        building.monthlyMaintenanceCost = spendings.rounded(toPlaces: 0)
         */
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
}

enum UpdateOfferError: Error {
    case offerDoesNotExist
}
