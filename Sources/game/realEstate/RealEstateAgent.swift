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
    case flat
}

protocol RealEstateAgentDelegate {
    func notifyWalletChange(playerUUID: String)
    func notifyEveryone(_ notification: UINotification)
    func reloadMap()
}

class RealEstateAgent {
    let mapManager: GameMapManager
    let centralBank: CentralBank
    let priceList: PriceList
    var delegate: RealEstateAgentDelegate?
    let dataStore: DataStoreProvider
    
    init(mapManager: GameMapManager, centralBank: CentralBank, delegate: RealEstateAgentDelegate? = nil) {
        self.mapManager = mapManager
        self.dataStore = centralBank.dataStore
        self.centralBank = centralBank
        self.delegate = delegate
        self.priceList = PriceList()
    }
    
    func syncMapWithDataStore() {
        
        var buildingToAdd: [ResidentialBuilding] = []
        for tile in self.mapManager.map.tiles {
            switch tile.type {
            case .building(let size):
                let building = ResidentialBuilding(land: Land(address: tile.address, ownerUUID: SystemPlayer.government.uuid), storeyAmount: size)
                buildingToAdd.append(building)
            default:
                break
            }
        }
        
        let lands: [Land] = self.dataStore.getAll()
        for land in lands  {
            let tile = GameMapTile(address: land.address, type: .soldLand)
            self.mapManager.map.replaceTile(tile: tile)
        }
        let roads: [Road] = self.dataStore.getAll()
        for road in roads {
            if road.isUnderConstruction {
                let tile = GameMapTile(address: road.address, type: .streetUnderConstruction)
                self.mapManager.map.replaceTile(tile: tile)
            } else {
                self.mapManager.addStreet(address: road.address)
            }
        }
        
        let buildings: [ResidentialBuilding] = self.dataStore.getAll()
        for building in buildings {
            if building.isUnderConstruction {
                let tile = GameMapTile(address: building.address, type: .buildingUnderConstruction(size: building.storeyAmount))
                self.mapManager.map.replaceTile(tile: tile)
            } else {
                let tile = GameMapTile(address: building.address, type: .building(size: building.storeyAmount))
                self.mapManager.map.replaceTile(tile: tile)
            }
        }
        for building in buildingToAdd {
            if (!buildings.contains{ $0.address == building.address }) {
                self.dataStore.create(building)
            }
        }
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
        return false
    }

    func getProperty(address: MapPoint) -> Property? {
        
        guard let tile = self.mapManager.map.getTile(address: address) else {
            return nil
        }
        if tile.isStreet() || tile.isStreetUnderConstruction() {
            let road: Road? = self.dataStore.find(address: address)
            return road
        }
        if tile.isBuilding() {
            let building: ResidentialBuilding? = self.dataStore.find(address: address)
            return building
        }
        if tile.isSoldLand() {
            let land: Land? = self.dataStore.find(address: address)
            return land
        }
        return nil
    }

    func landSaleOffer(address: MapPoint, buyerUUID: String) -> SaleOffer? {
        let tile = self.mapManager.map.getTile(address: address)
        guard tile == nil else {
            return nil
        }
        let name = "\(RandomNameGenerator.randomAdjective.capitalized) \(RandomNameGenerator.randomNoun.capitalized)"
        let price = self.estimateLandValue(address)
        var commission = price * self.priceList.realEstateSellPropertyCommisionFee
        if commission < 100 { commission = 100 }
        let saleInvoice = Invoice(title: "Purchase land \(name)", netValue: price, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        let commissionInvoice = Invoice(title: "Commission for purchase land \(name)", grossValue: commission, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        let land = Land(address: address, name: name, ownerUUID: buyerUUID, purchaseNetValue: saleInvoice.netValue)
        
        return SaleOffer(saleInvoice: saleInvoice, commissionInvoice: commissionInvoice, property: land)
    }
    
    func residentialBuildingSaleOffer(address: MapPoint, buyerUUID: String) -> SaleOffer? {
        guard let tile = self.mapManager.map.getTile(address: address), tile.isBuilding() else {
            return nil
        }
        guard let building: ResidentialBuilding = self.dataStore.find(address: address) else {
            return nil
        }
        let price = self.estimateResidentialBuildingValue(address)
        var commission = price * self.priceList.realEstateSellPropertyCommisionFee
        if commission < 100 { commission = 100 }
        let saleInvoice = Invoice(title: "Purchase \(building.name)", netValue: price, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        let commissionInvoice = Invoice(title: "Commission for purchase land \(building.name)", grossValue: commission, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        
        return SaleOffer(saleInvoice: saleInvoice, commissionInvoice: commissionInvoice, property: building)
    }

    func buyLandProperty(address: MapPoint, buyerUUID: String) throws {
        
        guard let offer = self.landSaleOffer(address: address, buyerUUID: buyerUUID) else {
            throw BuyPropertyError.propertyNotForSale
        }
       
        guard let land = offer.property as? Land else {
            throw BuyPropertyError.propertyNotForSale
        }
        let governmentID = SystemPlayer.government.uuid
        let realEstateAgentID = SystemPlayer.realEstateAgency.uuid
        // process the transaction
        var transaction = FinancialTransaction(payerID: buyerUUID, recipientID: governmentID , invoice: offer.saleInvoice)
        do {
             try self.centralBank.process(transaction)
        } catch let error as FinancialTransactionError {
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        transaction = FinancialTransaction(payerID: buyerUUID, recipientID: realEstateAgentID, invoice: offer.commissionInvoice)
        do {
             try self.centralBank.process(transaction)
        } catch let error as FinancialTransactionError {
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        self.dataStore.create(land)

        self.mapManager.map.replaceTile(tile: land.mapTile)
        
        self.delegate?.notifyWalletChange(playerUUID: buyerUUID)
        self.delegate?.reloadMap()
        let playerName = self.dataStore.find(uuid: buyerUUID)?.login ?? ""
        self.delegate?.notifyEveryone(UINotification(text: "New transaction on the market. Player \(playerName) has just bought property `\(land.name)`", level: .info, duration: 10))
    }
    
    func buyResidentialBuilding(address: MapPoint, buyerUUID: String) throws {
        
        guard let offer = self.residentialBuildingSaleOffer(address: address, buyerUUID: buyerUUID) else {
            throw BuyPropertyError.propertyNotForSale
        }
       
        guard let building = offer.property as? ResidentialBuilding else {
            throw BuyPropertyError.propertyNotForSale
        }
        let recipientID = building.ownerUUID ?? SystemPlayer.government.uuid
        let realEstateAgentID = SystemPlayer.realEstateAgency.uuid
        // process the transaction
        var transaction = FinancialTransaction(payerID: buyerUUID, recipientID: recipientID , invoice: offer.saleInvoice)
        do {
             try self.centralBank.process(transaction)
        } catch let error as FinancialTransactionError {
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        transaction = FinancialTransaction(payerID: buyerUUID, recipientID: realEstateAgentID, invoice: offer.commissionInvoice)
        do {
             try self.centralBank.process(transaction)
        } catch let error as FinancialTransactionError {
            throw BuyPropertyError.financialTransactionProblem(error)
        }
        
        let mutation = ResidentialBuildingMutation(uuid: building.uuid, attributes: [.ownerUUID(buyerUUID), .purchaseNetValue(offer.saleInvoice.netValue)])
        self.dataStore.update(mutation)
        
        self.delegate?.notifyWalletChange(playerUUID: buyerUUID)
        let playerName = self.dataStore.find(uuid: buyerUUID)?.login ?? ""
        self.delegate?.notifyEveryone(UINotification(text: "New transaction on the market. Player \(playerName) has just bought property `\(building.name)`", level: .info, duration: 10))
    }
    
    func instantSell(address: MapPoint, playerUUID: String) {
        guard var property = self.getProperty(address: address) else {
            Logger.error("RealEstateAgent", "Could not find property at \(address.description)")
            return
        }
        guard property.ownerUUID == playerUUID else {
            let name = self.dataStore.find(uuid: playerUUID)?.login ?? ""
            Logger.error("RealEstateAgent", "Player \(name) is not owner of property \(property.ownerUUID)")
            return
        }
        let governmentID = SystemPlayer.government.uuid

        // road will dissapear as roads are not for sale
        if property is Road {
            self.dataStore.removeRoad(uuid: property.uuid)
        } else if let building = property as? ResidentialBuilding {
            let apartments = Storage.shared.getApartments(address: building.address).filter { $0.ownerUUID == building.ownerUUID }
            for apartment in apartments {
                apartment.ownerUUID = governmentID
            }
            self.dataStore.update(ResidentialBuildingMutation(uuid: building.uuid, attributes: [.ownerUUID(governmentID)]))
            self.recalculateFeesInTheBuilding(building)
        } else if let land = property as? Land {
            self.dataStore.update(LandMutation(uuid: land.uuid, attributes: [.ownerUUID(governmentID)]))
            
        }
        
        guard let value = self.estimateValue(property.address) else {
            return
        }
        let sellPrice = (value * self.priceList.instantSellValue).rounded(toPlaces: 0)
        
        let invoice = Invoice(title: "Selling property \(property.name)", netValue: sellPrice, taxRate: self.centralBank.taxRates.instantSellTax)
        let transaction = FinancialTransaction(payerID: governmentID, recipientID: playerUUID, invoice: invoice)
    
        try? self.centralBank.process(transaction)
        if property.accountantID != nil {
            self.centralBank.refundIncomeTax(receiverID: playerUUID, transaction: transaction, costs: (property.investmentsNetValue + (property.purchaseNetValue ?? 0.0)))
        }
        self.delegate?.notifyWalletChange(playerUUID: playerUUID)
    }
    
    func instantApartmentSell(_ apartment: Apartment, playerUUID: String) {
        
        guard let building: ResidentialBuilding = self.dataStore.find(address: apartment.address) else {
            Logger.error("RealEstateAgent", "Could not find the building for apartment \(apartment.uuid)")
            return
        }
        let value = self.estimateApartmentValue(apartment)
        let sellPrice = (value * self.priceList.instantSellValue).rounded(toPlaces: 0)
        let governmentID = SystemPlayer.government.uuid
        let invoice = Invoice(title: "Selling apartment \(apartment.name)", netValue: sellPrice, taxRate: self.centralBank.taxRates.instantSellTax)
        let transaction = FinancialTransaction(payerID: governmentID, recipientID: playerUUID, invoice: invoice)
        // TODO: Add error handling
        try? self.centralBank.process(transaction)
        
        // if user had built this building, he had costs, so this costs' taxes can be refunded, provided he has accountant
        if building.ownerUUID == playerUUID, building.accountantID != nil {
            let costs = (((building.purchaseNetValue ?? 0.0) + building.investmentsNetValue)/(Double(building.numberOfFlats))).rounded(toPlaces: 0)
            self.centralBank.refundIncomeTax(receiverID: playerUUID, transaction: transaction, costs: costs)
        }
        apartment.ownerUUID = governmentID
        self.recalculateFeesInTheBuilding(building)
    
        self.delegate?.notifyWalletChange(playerUUID: playerUUID)
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
    
    private func estimateLandValue(_ address: MapPoint) -> Double {
        return (self.priceList.baseLandValue * self.calculateLocationValueFactor(address)).rounded(toPlaces: 0)
    }
    
    private func estimateRoadValue(_ address: MapPoint) -> Double {
        return 0
    }
    
    private func estimateResidentialBuildingValue(_ address: MapPoint) -> Double {
        return 10
    }
    
    func estimateValue(_ address: MapPoint) -> Double? {
        
        guard let tile = self.mapManager.map.getTile(address: address) else {
            return self.estimateLandValue(address)
        }

        if tile.isStreet() || tile.isStreetUnderConstruction() {
            return self.estimateRoadValue(address)
        }
        if tile.isBuilding() {
            return self.estimateResidentialBuildingValue(address)
        }
        return nil
    }
    
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
    
    private func calculateLocationValueFactor(_ address: MapPoint) -> Double {
        // in future add price relation to bus stop
        
        func getBuildingsFactor(_ address: MapPoint) -> Double {
            var startPrice = 1.0
            for distance in (1...4) {
                for streetAddress in self.mapManager.map.getNeighbourAddresses(to: address, radius: distance) {
                    if let tile = self.mapManager.map.getTile(address: streetAddress), tile.isStreet() {
                        
                        if distance == 1 {
                            
                            for buildingDistance in (1...3) {
                                var numberOfBuildings = 0
                                for buildingAddress in self.mapManager.map.getNeighbourAddresses(to: address, radius: buildingDistance) {
                                    if let tile = self.mapManager.map.getTile(address: buildingAddress), tile.isBuilding() {
                                        numberOfBuildings += 1
                                    }
                                }
                                if numberOfBuildings > 0 {
                                    let factor = self.priceList.propertyValueDistanceFromResidentialBuildingGain/buildingDistance.double
                                    startPrice = startPrice * (1 + numberOfBuildings.double * factor)
                                }
                            }
                        }
                        return startPrice
                    }
                }
                startPrice = startPrice * self.priceList.propertyValueDistanceFromRoadLoss
            }
            return startPrice
        }
        
        func getAntennaFactor(_ address: MapPoint) -> Double {
            var startPrice = 1.0
            for distance in (1...3) {
                for streetAddress in self.mapManager.map.getNeighbourAddresses(to: address, radius: distance) {
                    if let tile = self.mapManager.map.getTile(address: streetAddress), tile.isAntenna() {
                        startPrice = startPrice * self.priceList.propertyValueAntennaSurroundingLoss * distance.double
                    }
                }
            }
            return startPrice
        }
        return getBuildingsFactor(address) * getAntennaFactor(address) * (1 + self.occupiedSpaceOnMapFactor())
    }
    
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
    
    private func occupiedSpaceOnMapFactor() -> Double {
        return Double(self.mapManager.map.tiles.count) / Double(self.mapManager.map.width * self.mapManager.map.height)
    }
 }


enum BuyPropertyError: Error {
    case propertyNotForSale
    case financialTransactionProblem(FinancialTransactionError)
}
