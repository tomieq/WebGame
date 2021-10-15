//
//  RealEstateAgent.swift
//  
//
//  Created by Tomasz Kucharski on 17/03/2021.
//

import Foundation

enum PropertyType {
    case land
    case road
    case residentialBuilding
}

class RealEstateAgent {
    let mapManager: GameMapManager
    private var mapping: [MapPoint:PropertyType]
    
    init(mapManager: GameMapManager) {
        self.mapManager = mapManager
        self.mapping = [:]
        
        for land in Storage.shared.landProperties {
            self.mapping[land.address] = .land
            let tile = GameMapTile(address: land.address, type: .soldLand)
            self.mapManager.map.replaceTile(tile: tile)
        }
        for road in Storage.shared.roadProperties {
            self.mapping[road.address] = .road
            self.mapManager.addStreet(address: road.address)
        }
        
        for building in Storage.shared.residentialBuildings {
            self.mapping[building.address] = .residentialBuilding
            if building.isUnderConstruction {
                let tile = GameMapTile(address: building.address, type: .buildingUnderConstruction(size: building.storeyAmount))
                self.mapManager.map.replaceTile(tile: tile)
            } else {
                let tile = GameMapTile(address: building.address, type: .building(size: building.storeyAmount))
                self.mapManager.map.replaceTile(tile: tile)
            }
        }
    }
    
    func isForSale(address: MapPoint) -> Bool {
        if self.getProperty(address: address)?.ownerID == DataStore.provider.getPlayer(type: .government)?.uuid {
            return true
        }
        return self.mapManager.map.getTile(address: address) == nil
    }
    
    func getProperty(address: MapPoint) -> Property? {
        guard let type = self.mapping[address] else {
            return nil
        }
        switch type {
        case .land:
            return Storage.shared.landProperties.first { $0.address == address }
        case .road:
            return Storage.shared.roadProperties.first { $0.address == address }
        case .residentialBuilding:
            return Storage.shared.residentialBuildings.first { $0.address == address }
        }
    }

    func buyLandProperty(address: MapPoint, session: PlayerSession) throws {
        
        guard self.isForSale(address: address) else {
            throw BuyPropertyError.propertyNotForSale
        }
        let land = (Storage.shared.landProperties.first{ $0.address == address }) ?? Land(address: address)
        let price = self.estimateValue(land)
        let invoice = Invoice(title: "Purchase land \(land.name)", netValue: price, taxRate: TaxRates.propertyPurchaseTax)
        let commissionInvoice = Invoice(title: "Commission for purchase land \(land.name)", grossValue: price*PriceList.realEstateSellPropertyCommisionFee, taxRate: TaxRates.propertyPurchaseTax)
        
        let governmentID = DataStore.provider.getPlayer(type: .government)?.uuid ?? ""
        let realEstateAgentID = DataStore.provider.getPlayer(type: .realEstateAgency)?.uuid ?? ""
        // process the transaction
        var transaction = FinancialTransaction(payerID: session.player.uuid, recipientID: governmentID , invoice: invoice)
        if case .failure(let reason) = CentralBank.shared.process(transaction) {
            throw BuyPropertyError.financialTransactionProblem(reason: reason)
        }
        transaction = FinancialTransaction(payerID: session.player.uuid, recipientID: realEstateAgentID, invoice: commissionInvoice)
        if case .failure(let reason) = CentralBank.shared.process(transaction) {
            throw BuyPropertyError.financialTransactionProblem(reason: reason)
        }
        
        land.ownerID = session.player.uuid
        land.purchaseNetValue = invoice.netValue
        
        self.mapping[land.address] = .land
        Storage.shared.landProperties = Storage.shared.landProperties.filter { $0.address != address }
        Storage.shared.landProperties.append(land)

        self.mapManager.map.replaceTile(tile: land.mapTile)
        
        if let player = DataStore.provider.getPlayer(id: session.player.uuid) {
            let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(player.wallet.money))
            GameEventBus.gameEvents.onNext(updateWalletEvent)
        }
        
        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
        
        let announcementEvent = GameEvent(playerSession: nil, action: .notification(UINotification(text: "New transaction on the market. Player \(session.player.login) has just bought property `\(land.name)`", level: .info, duration: 10)))
        GameEventBus.gameEvents.onNext(announcementEvent)
    }
    
    func instantSell(address: MapPoint, session: PlayerSession) {
        guard var property = self.getProperty(address: address) else {
            Logger.error("RealEstateAgent", "Could not find property at \(address.description)")
            return
        }
        guard property.ownerID == session.player.uuid else {
            Logger.error("RealEstateAgent", "Player \(session.player.login) is not owner of property \(property.id)")
            return
        }
        guard let government = DataStore.provider.getPlayer(type: .government) else {
            Logger.error("RealEstateAgent", "Could not find goverment player")
            return
        }
        // road will dissapear as roads are not for sale
        if property is Road {
            Storage.shared.roadProperties = Storage.shared.roadProperties.filter { $0.address != address }
            self.mapping[property.address] = nil
        }
        if let building = property as? ResidentialBuilding {
            let apartments = Storage.shared.getApartments(address: building.address).filter { $0.ownerID == building.ownerID }
            for apartment in apartments {
                apartment.ownerID = government.uuid
            }
            building.ownerID = government.uuid
            self.recalculateFeesInTheBuilding(building)
        }
        property.ownerID = government.uuid
        
        let value = self.estimateValue(property)
        let sellPrice = (value * PriceList.instantSellValue).rounded(toPlaces: 0)
        
        let invoice = Invoice(title: "Selling property \(property.name)", netValue: sellPrice, taxRate: TaxRates.instantSellTax)
        let transaction = FinancialTransaction(payerID: government.uuid, recipientID: session.player.uuid, invoice: invoice)
        CentralBank.shared.process(transaction)
        if property.accountantID != nil {
            CentralBank.shared.refundIncomeTax(receiverID: session.player.uuid, transaction: transaction, costs: (property.investmentsNetValue + (property.purchaseNetValue ?? 0.0)))
        }
        if let player = DataStore.provider.getPlayer(id: session.player.uuid) {
            let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(player.wallet.money))
            GameEventBus.gameEvents.onNext(updateWalletEvent)
        }
    }
    
    func instantApartmentSell(_ apartment: Apartment, session: PlayerSession) {
        guard let government = DataStore.provider.getPlayer(type: .government) else {
            Logger.error("RealEstateAgent", "Could not find goverment player")
            return
        }
        guard let building = (Storage.shared.residentialBuildings.first { $0.address == apartment.address }) else {
            Logger.error("RealEstateAgent", "Could not find the building for apartment \(apartment.id)")
            return
        }
        let value = self.estimateApartmentValue(apartment)
        let sellPrice = (value * PriceList.instantSellValue).rounded(toPlaces: 0)
        
        let invoice = Invoice(title: "Selling apartment \(apartment.name)", netValue: sellPrice, taxRate: TaxRates.instantSellTax)
        let transaction = FinancialTransaction(payerID: government.uuid, recipientID: session.player.uuid, invoice: invoice)
        CentralBank.shared.process(transaction)
        
        // if user had built this building, he had costs, so this costs' taxes can be refunded, provided he has accountant
        if building.ownerID == session.player.uuid, building.accountantID != nil {
            let costs = (((building.purchaseNetValue ?? 0.0) + building.investmentsNetValue)/(Double(building.numberOfFlats))).rounded(toPlaces: 0)
            CentralBank.shared.refundIncomeTax(receiverID: session.player.uuid, transaction: transaction, costs: costs)
        }
        apartment.ownerID = government.uuid
        self.recalculateFeesInTheBuilding(building)
    
        if let player = DataStore.provider.getPlayer(id: session.player.uuid) {
            let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(player.wallet.money))
            GameEventBus.gameEvents.onNext(updateWalletEvent)
        }
    }
    
    func rentApartment(_ apartment: Apartment) {
        apartment.isRented = true
        if let building = (Storage.shared.residentialBuildings.first { $0.address == apartment.address }) {
            self.recalculateFeesInTheBuilding(building)
        }
    }
    
    func unrentApartment(_ apartment: Apartment) {
        apartment.isRented = false
        if let building = (Storage.shared.residentialBuildings.first { $0.address == apartment.address }) {
            self.recalculateFeesInTheBuilding(building)
        }
    }
    
    func buildRoad(address: MapPoint, session: PlayerSession) throws {
        
        guard let land = (Storage.shared.landProperties.first { $0.address == address}) else {
            throw StartInvestmentError.formalProblem(reason: "You can build road only on an empty land.")
        }
        guard land.ownerID == session.player.uuid else {
            throw StartInvestmentError.formalProblem(reason: "You can invest only on your properties.")
        }
        guard self.hasDirectAccessToRoad(address: address) else {
            throw StartInvestmentError.formalProblem(reason: "You cannot build road here as this property has no direct access to the public road.")
        }
        let governmentID = DataStore.provider.getPlayer(type: .government)?.uuid ?? ""
        let invoice = Invoice(title: "Build road on property \(land.name)", netValue: InvestmentCost.makeRoadCost(), taxRate: TaxRates.investmentTax)
        // process the transaction
        let transaction = FinancialTransaction(payerID: session.player.uuid, recipientID: governmentID, invoice: invoice)
        if case .failure(let reason) = CentralBank.shared.process(transaction) {
            throw StartInvestmentError.financialTransactionProblem(reason: reason)
        }
        
        let road = Road(land: land)
        Storage.shared.landProperties = Storage.shared.landProperties.filter { $0.address != address }
        Storage.shared.roadProperties.append(road)
        self.mapping[land.address] = .road
        
        self.mapManager.addStreet(address: address)
        
        if let player = DataStore.provider.getPlayer(id: session.player.uuid) {
            let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(player.wallet.money))
            GameEventBus.gameEvents.onNext(updateWalletEvent)
        }

        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
    }
    
    
    func buildResidentialBuilding(address: MapPoint, session: PlayerSession, storeyAmount: Int) throws {
        
        guard let land = (Storage.shared.landProperties.first { $0.address == address}) else {
            throw StartInvestmentError.formalProblem(reason: "You can build road only on an empty land.")
        }
        guard land.ownerID == session.player.uuid else {
            throw StartInvestmentError.formalProblem(reason: "You can invest only on your properties.")
        }
        guard self.hasDirectAccessToRoad(address: address) else {
            throw StartInvestmentError.formalProblem(reason: "You cannot build apartment here as this property has no direct access to the public road.")
        }
        let building = ResidentialBuilding(land: land, storeyAmount: storeyAmount)
        building.isUnderConstruction = true
        building.constructionFinishMonth = Storage.shared.monthIteration + InvestmentDuration.buildingApartment(storey: storeyAmount)
        let invoice = Invoice(title: "Build \(storeyAmount)-storey \(building.name)", netValue: InvestmentCost.makeResidentialBuildingCost(storey: storeyAmount), taxRate: TaxRates.investmentTax)
        // process the transaction
        let governmentID = DataStore.provider.getPlayer(type: .government)?.uuid ?? ""
        let transaction = FinancialTransaction(payerID: session.player.uuid, recipientID: governmentID, invoice: invoice)
        if case .failure(let reason) = CentralBank.shared.process(transaction) {
            throw StartInvestmentError.financialTransactionProblem(reason: reason)
        }
        Storage.shared.landProperties = Storage.shared.landProperties.filter { $0.address != address }
        Storage.shared.residentialBuildings.append(building)
        self.mapping[land.address] = .residentialBuilding
        
        let tile = GameMapTile(address: address, type: .buildingUnderConstruction(size: storeyAmount))
        self.mapManager.map.replaceTile(tile: tile)
        
        if let player = DataStore.provider.getPlayer(id: session.player.uuid) {
            let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(player.wallet.money))
            GameEventBus.gameEvents.onNext(updateWalletEvent)
        }

        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
    }
    
    func estimateValue(_ property: Property) -> Double {
        if let land = property as? Land, let value = self.estimateLandValue(land) {
            return value * (1 + self.occupiedSpaceOnMapFactor())
        }
        if let _ = property as? Road {
            return 0.0
        }
        if let building = property as? ResidentialBuilding {
            var basePrice = self.estimateValue(Land(address: building.address))
            let apartments = Storage.shared.getApartments(address: building.address).filter { $0.ownerID == building.ownerID }
            for apartment in apartments {
                basePrice += self.estimateApartmentValue(apartment)
            }
            return basePrice.rounded(toPlaces: 0)
        }
        Logger.error("RealEstateAgent", "Couldn't estimate value for \(type(of: property)) \(property.id)!")
        return 900000000
    }
    
    func estimateApartmentValue(_ apartment: Apartment) -> Double {
        if let building = (Storage.shared.residentialBuildings.first{ $0.address == apartment.address }) {
            let investmentCost = InvestmentCost.makeResidentialBuildingCost(storey: building.storeyAmount)
            let numberOfFlats = Double(building.numberOfFlatsPerStorey * building.storeyAmount)
            let baseValue = (investmentCost/numberOfFlats + PriceList.residentialBuildingOwnerIncomeOnFlatSellPrice) * 1.42
            // TODO: add dependency on neighbourhood
            return (baseValue * building.condition/100 * apartment.condition/100).rounded(toPlaces: 0)
        }
        Logger.error("RealEstateAgent", "Apartment \(apartment.id) is detached from building!")
        return 900000000
    }
    
    func estimateRentFee(_ apartment: Apartment) -> Double {
        if let building = (Storage.shared.residentialBuildings.first { $0.address == apartment.address }) {
            return (PriceList.monthlyApartmentRentalFee * building.condition/100 * apartment.condition/100).rounded(toPlaces: 0)
        }
        return 0.0
    }
    
    private func estimateLandValue(_ land: Land) -> Double? {
        // in future add price relation to bus stop
        var startPrice = PriceList.baseLandValue

        for distance in (1...4) {
            for streetAddress in self.mapManager.map.getNeighbourAddresses(to: land.address, radius: distance) {
                if let tile = self.mapManager.map.getTile(address: streetAddress), tile.isStreet() {
                    
                    if distance == 1 {
                        
                        for buildingDistance in (1...3) {
                            var numberOfBuildings = 0
                            for buildingAddress in self.mapManager.map.getNeighbourAddresses(to: land.address, radius: buildingDistance) {
                                if let tile = self.mapManager.map.getTile(address: buildingAddress), tile.isBuilding() {
                                    numberOfBuildings += 1
                                }
                            }
                            if numberOfBuildings > 0 {
                                let factor = PriceList.propertyValueDistanceFromResidentialBuildingGain/buildingDistance.double
                                startPrice = startPrice * (1 + numberOfBuildings.double * factor)
                            }
                        }
                    }
                    return startPrice
                }
            }
            startPrice = startPrice * PriceList.propertyValueDistanceFromRoadLoss
        }
        return startPrice
    }
    
    func recalculateFeesInTheBuilding(_ building: ResidentialBuilding) {
        
        let baseBuildingMonthlyCosts: Double = PriceList.montlyResidentialBuildingCost + PriceList.montlyResidentialBuildingCostPerStorey * building.storeyAmount.double
        let numberOfFlats = Double(building.storeyAmount * building.numberOfFlatsPerStorey)
        
        let buildingCostPerFlat = (baseBuildingMonthlyCosts/numberOfFlats + PriceList.monthlyResidentialBuildingOwnerIncomePerFlat).rounded(toPlaces: 0)
        
        var income: Double = 0
        var spendings = baseBuildingMonthlyCosts
        for apartment in Storage.shared.getApartments(address: building.address) {
            
            switch apartment.isRented {
                case true:
                apartment.monthlyRentalFee = self.estimateRentFee(apartment)
                apartment.monthlyBills = PriceList.monthlyBillsForRentedApartment
                case false:
                apartment.monthlyRentalFee = 0
                apartment.monthlyBills = PriceList.monthlyBillsForUnrentedApartment
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
    }
    
    private func occupiedSpaceOnMapFactor() -> Double {
        return Double(self.mapManager.map.tiles.count) / Double(self.mapManager.map.width * self.mapManager.map.height)
    }
    
    func hasDirectAccessToRoad(address: MapPoint) -> Bool {
        return ![address.move(.up),address.move(.down),address.move(.left),address.move(.right)]
        .compactMap { self.mapManager.map.getTile(address: $0) }
        .filter{ $0.isStreet() }.isEmpty
    }
 }


enum BuyPropertyError: Error {
    case propertyNotForSale
    case financialTransactionProblem(reason: String)
}

enum StartInvestmentError: Error {
    case formalProblem(reason: String)
    case financialTransactionProblem(reason: String)
}
