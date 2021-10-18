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
    
    func makeMapTilesFromDataStore() {
        for land in Storage.shared.landProperties {
            let tile = GameMapTile(address: land.address, type: .soldLand)
            self.mapManager.map.replaceTile(tile: tile)
        }
        for road in Storage.shared.roadProperties {
            self.mapManager.addStreet(address: road.address)
        }
        
        for building in Storage.shared.residentialBuildings {
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
        if self.getProperty(address: address)?.ownerID == self.dataStore.getPlayer(type: .government)?.uuid {
            return true
        }
        return self.mapManager.map.getTile(address: address) == nil
    }
    
    func getProperty(address: MapPoint) -> Property? {
        let tile = self.mapManager.map.getTile(address: address)
        if tile?.isStreet() ?? false {
            return Storage.shared.roadProperties.first { $0.address == address }
        }
        if tile?.isBuilding() ?? false {
            return Storage.shared.residentialBuildings.first { $0.address == address }
        }
        
        return Storage.shared.landProperties.first { $0.address == address }
    }

    func buyLandProperty(address: MapPoint, playerUUID: String) throws {
        
        guard self.isForSale(address: address) else {
            throw BuyPropertyError.propertyNotForSale
        }
        let land = (Storage.shared.landProperties.first{ $0.address == address }) ?? Land(address: address)
        let price = self.estimateValue(land.address)
        let invoice = Invoice(title: "Purchase land \(land.name)", netValue: price, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        let commissionInvoice = Invoice(title: "Commission for purchase land \(land.name)", grossValue: price*self.priceList.realEstateSellPropertyCommisionFee, taxRate: self.centralBank.taxRates.propertyPurchaseTax)
        
        let governmentID = self.dataStore.getPlayer(type: .government)?.uuid ?? ""
        let realEstateAgentID = self.dataStore.getPlayer(type: .realEstateAgency)?.uuid ?? ""
        // process the transaction
        var transaction = FinancialTransaction(payerID: playerUUID, recipientID: governmentID , invoice: invoice)
        if case .failure(let reason) = self.centralBank.process(transaction) {
            throw BuyPropertyError.financialTransactionProblem(reason: reason)
        }
        transaction = FinancialTransaction(payerID: playerUUID, recipientID: realEstateAgentID, invoice: commissionInvoice)
        if case .failure(let reason) = self.centralBank.process(transaction) {
            throw BuyPropertyError.financialTransactionProblem(reason: reason)
        }
        
        land.ownerID = playerUUID
        land.purchaseNetValue = invoice.netValue
        
        Storage.shared.landProperties = Storage.shared.landProperties.filter { $0.address != address }
        Storage.shared.landProperties.append(land)

        self.mapManager.map.replaceTile(tile: land.mapTile)
        
        self.delegate?.notifyWalletChange(playerUUID: playerUUID)
        self.delegate?.reloadMap()
        let name = self.dataStore.find(uuid: playerUUID)?.login ?? ""
        self.delegate?.notifyEveryone(UINotification(text: "New transaction on the market. Player \(name) has just bought property `\(land.name)`", level: .info, duration: 10))
    }
    
    func instantSell(address: MapPoint, playerUUID: String) {
        guard var property = self.getProperty(address: address) else {
            Logger.error("RealEstateAgent", "Could not find property at \(address.description)")
            return
        }
        guard property.ownerID == playerUUID else {
            let name = self.dataStore.find(uuid: playerUUID)?.login ?? ""
            Logger.error("RealEstateAgent", "Player \(name) is not owner of property \(property.id)")
            return
        }
        guard let government = self.dataStore.getPlayer(type: .government) else {
            Logger.error("RealEstateAgent", "Could not find goverment player")
            return
        }
        // road will dissapear as roads are not for sale
        if property is Road {
            Storage.shared.roadProperties = Storage.shared.roadProperties.filter { $0.address != address }
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
        
        let value = self.estimateValue(property.address)
        let sellPrice = (value * self.priceList.instantSellValue).rounded(toPlaces: 0)
        
        let invoice = Invoice(title: "Selling property \(property.name)", netValue: sellPrice, taxRate: self.centralBank.taxRates.instantSellTax)
        let transaction = FinancialTransaction(payerID: government.uuid, recipientID: playerUUID, invoice: invoice)
    
        self.centralBank.process(transaction)
        if property.accountantID != nil {
            self.centralBank.refundIncomeTax(receiverID: playerUUID, transaction: transaction, costs: (property.investmentsNetValue + (property.purchaseNetValue ?? 0.0)))
        }
        self.delegate?.notifyWalletChange(playerUUID: playerUUID)
    }
    
    func instantApartmentSell(_ apartment: Apartment, playerUUID: String) {
        guard let government = self.dataStore.getPlayer(type: .government) else {
            Logger.error("RealEstateAgent", "Could not find goverment player")
            return
        }
        guard let building = (Storage.shared.residentialBuildings.first { $0.address == apartment.address }) else {
            Logger.error("RealEstateAgent", "Could not find the building for apartment \(apartment.id)")
            return
        }
        let value = self.estimateApartmentValue(apartment)
        let sellPrice = (value * self.priceList.instantSellValue).rounded(toPlaces: 0)
        
        let invoice = Invoice(title: "Selling apartment \(apartment.name)", netValue: sellPrice, taxRate: self.centralBank.taxRates.instantSellTax)
        let transaction = FinancialTransaction(payerID: government.uuid, recipientID: playerUUID, invoice: invoice)
        self.centralBank.process(transaction)
        
        // if user had built this building, he had costs, so this costs' taxes can be refunded, provided he has accountant
        if building.ownerID == playerUUID, building.accountantID != nil {
            let costs = (((building.purchaseNetValue ?? 0.0) + building.investmentsNetValue)/(Double(building.numberOfFlats))).rounded(toPlaces: 0)
            self.centralBank.refundIncomeTax(receiverID: playerUUID, transaction: transaction, costs: costs)
        }
        apartment.ownerID = government.uuid
        self.recalculateFeesInTheBuilding(building)
    
        self.delegate?.notifyWalletChange(playerUUID: playerUUID)
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
    
    func estimateValue(_ address: MapPoint) -> Double {
        
        let tile = self.mapManager.map.getTile(address: address)

        if tile?.isStreet() ?? false {
            return 0.0
        }
        var basePrice = self.priceList.baseLandValue * self.calculateLocationValueFactor(address)
        if tile?.isBuilding() ?? false {
            
            let apartments = Storage.shared.getApartments(address: address)//.filter { $0.ownerID == building.ownerID }
            for apartment in apartments {
                basePrice += self.estimateApartmentValue(apartment)
            }
            return basePrice.rounded(toPlaces: 0)
        }
        return basePrice.rounded(toPlaces: 0)
    }
    
    func estimateApartmentValue(_ apartment: Apartment) -> Double {
        if let building = (Storage.shared.residentialBuildings.first{ $0.address == apartment.address }) {
            let investmentCost = 0.0//ConstructionPriceList.makeResidentialBuildingCost(storey: building.storeyAmount)
            let numberOfFlats = Double(building.numberOfFlatsPerStorey * building.storeyAmount)
            let baseValue = (investmentCost/numberOfFlats + self.priceList.residentialBuildingOwnerIncomeOnFlatSellPrice) * 1.42
            return (baseValue * building.condition/100 * apartment.condition/100 * self.calculateLocationValueFactor(building.address)).rounded(toPlaces: 0)
        }
        Logger.error("RealEstateAgent", "Apartment \(apartment.id) is detached from building!")
        return 900000000
    }
    
    func estimateRentFee(_ apartment: Apartment) -> Double {
        if let building = (Storage.shared.residentialBuildings.first { $0.address == apartment.address }) {
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
    }
    
    private func occupiedSpaceOnMapFactor() -> Double {
        return Double(self.mapManager.map.tiles.count) / Double(self.mapManager.map.width * self.mapManager.map.height)
    }
 }


enum BuyPropertyError: Error {
    case propertyNotForSale
    case financialTransactionProblem(reason: String)
}
