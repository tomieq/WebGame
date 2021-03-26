//
//  RealEstateAgent.swift
//  
//
//  Created by Tomasz Kucharski on 17/03/2021.
//

import Foundation

class RealEstateAgent {
    private let mapManager: GameMapManager
    private var properties: [Property]
    
    init(mapManager: GameMapManager) {
        self.mapManager = mapManager
        self.properties = []
        
        Storage.shared.landProperties.forEach { land in
            self.properties.append(land)
            let tile = GameMapTile(address: land.address, type: .soldLand)
            self.mapManager.map.replaceTile(tile: tile)
        }
        Storage.shared.roadProperties.forEach { road in
            self.properties.append(road)
            self.mapManager.addStreet(address: road.address)
        }
        
        Storage.shared.residentialBuildings.forEach { building in
            self.properties.append(building)
            let tile = GameMapTile(address: building.address, type: .building(size: building.storeyAmount))
            self.mapManager.map.replaceTile(tile: tile)
        }
    }
    
    func isForSale(address: MapPoint) -> Bool {
        if self.getProperty(address: address)?.ownerID == SystemPlayerID.government.rawValue {
            return true
        }
        return self.mapManager.map.getTile(address: address) == nil
    }
    
    func getProperty(address: MapPoint) -> Property? {
        return self.properties.first { $0.address == address }
    }

    func getProperty(id: String) -> Property? {
        return self.properties.first { $0.id == id }
    }
    
    private func saveProperties() {
        Storage.shared.landProperties = self.properties.compactMap { $0 as? Land }
        Storage.shared.roadProperties = self.properties.compactMap { $0 as? Road }
        Storage.shared.residentialBuildings = self.properties.compactMap { $0 as? ResidentialBuilding }
    }
    
    func buyProperty(address: MapPoint, session: PlayerSession) throws {
        
        guard self.isForSale(address: address) else {
            throw BuyPropertyError.propertyNotForSale
        }
        var property = self.getProperty(address: address) ?? Land(address: address)
        let price = self.estimatePrice(property)
        let invoice = Invoice(netValue: price, taxPercent: TaxRates.propertyPurchaseTax, feePercent: 1)
        
        // process the transaction
        let transaction = FinancialTransaction(payerID: session.player.id, recipientID: SystemPlayerID.government.rawValue, feeRecipientID: SystemPlayerID.realEstateAgency.rawValue, invoice: invoice)
        if case .failure(let reason) = CentralBank.shared.process(transaction) {
            throw BuyPropertyError.financialTransactionProblem(reason: reason)
        }
        
        property.ownerID = session.player.id
        property.purchaseNetValue = invoice.netValue
        
        self.properties = self.properties.filter { $0.address != address }
        self.properties.append(property)
        self.saveProperties()
        if let land = property as? Land {
            self.mapManager.map.replaceTile(tile: land.mapTile)
        }
        
        let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
        GameEventBus.gameEvents.onNext(updateWalletEvent)
        
        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
        
        let announcementEvent = GameEvent(playerSession: nil, action: .notification(UINotification(text: "New transaction on the market. Player \(session.player.login) has just bought property `\(property.name)`", level: .info, duration: 10)))
        GameEventBus.gameEvents.onNext(announcementEvent)
    }
    
    func instantSell(address: MapPoint, session: PlayerSession) {
        guard var property = self.getProperty(address: address) else {
            Logger.error("RealEstateAgent", "Could not find property at \(address.description)")
            return
        }
        guard property.ownerID == session.player.id else {
            Logger.error("RealEstateAgent", "Player \(session.player.login) is not owner of property \(property.id)")
            return
        }
        guard let government = Storage.shared.getPlayer(id: SystemPlayerID.government.rawValue) else {
            Logger.error("RealEstateAgent", "Could not goverment player")
            return
        }
        // road will dissapear as roads are not for sale
        if property is Road {
            self.properties = self.properties.filter { $0.address != address }
        }
        if let building = property as? ResidentialBuilding {
            let apartments = Storage.shared.getApartments(address: building.address).filter { $0.ownerID == building.ownerID }
            for apartment in apartments {
                apartment.ownerID = government.id
            }
            building.ownerID = government.id
            self.recalculateFeesInTheBuilding(building)
        }
        property.ownerID = government.id
        self.saveProperties()
        
        let value = self.estimatePrice(property)
        let sellPrice = (value * PriceList.instantSellFraction).rounded(toPlaces: 0)
        
        session.player.addIncome(sellPrice)
        
        let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
        GameEventBus.gameEvents.onNext(updateWalletEvent)
    }
    
    func instantApartmentSell(_ apartment: Apartment, session: PlayerSession) {
        guard let government = Storage.shared.getPlayer(id: SystemPlayerID.government.rawValue) else {
            Logger.error("RealEstateAgent", "Could not goverment player")
            return
        }
        guard let building = self.getProperty(address: apartment.address) as? ResidentialBuilding else {
            Logger.error("RealEstateAgent", "Could not find the building for apartment \(apartment.id)")
            return
        }
        let value = self.estimateApartmentValue(apartment)
        let sellPrice = (value * PriceList.instantSellFraction).rounded(toPlaces: 0)
        
        session.player.addIncome(sellPrice)
        
        apartment.ownerID = government.id
        self.recalculateFeesInTheBuilding(building)
    
        let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
        GameEventBus.gameEvents.onNext(updateWalletEvent)
    }
    
    func rentApartment(_ apartment: Apartment) {
        apartment.isRented = true
        if let building = self.getProperty(address: apartment.address) as? ResidentialBuilding {
            self.recalculateFeesInTheBuilding(building)
        }
    }
    
    func unrentApartment(_ apartment: Apartment) {
        apartment.isRented = false
        if let building = self.getProperty(address: apartment.address) as? ResidentialBuilding {
            self.recalculateFeesInTheBuilding(building)
        }
    }
    
    func buildRoad(address: MapPoint, session: PlayerSession) throws {
        
        guard let land = (self.properties.first { $0.address == address}) as? Land else {
            throw StartInvestmentError.formalProblem(reason: "You can build road only on an empty land.")
        }
        guard land.ownerID == session.player.id else {
            throw StartInvestmentError.formalProblem(reason: "You can invest only on your properties.")
        }
        guard self.hasDirectAccessToRoad(address: address) else {
            throw StartInvestmentError.formalProblem(reason: "You cannot build road here as this property has no direct access to the public road.")
        }
        let invoice = Invoice(netValue: InvestmentPrice.buildingRoad(), taxPercent: TaxRates.investmentTax)
        // process the transaction
        let transaction = FinancialTransaction(payerID: session.player.id, recipientID: SystemPlayerID.government.rawValue, invoice: invoice)
        if case .failure(let reason) = CentralBank.shared.process(transaction) {
            throw StartInvestmentError.financialTransactionProblem(reason: reason)
        }
        
        let road = Road(land: land)
        self.properties = self.properties.filter { $0.address != address }
        self.properties.append(road)
        self.saveProperties()
        
        self.mapManager.addStreet(address: address)
        
        let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
        GameEventBus.gameEvents.onNext(updateWalletEvent)

        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
    }
    
    
    func buildResidentialBuilding(address: MapPoint, session: PlayerSession, storeyAmount: Int) throws {
        
        guard let land = (self.properties.first { $0.address == address}) as? Land else {
            throw StartInvestmentError.formalProblem(reason: "You can build road only on an empty land.")
        }
        guard land.ownerID == session.player.id else {
            throw StartInvestmentError.formalProblem(reason: "You can invest only on your properties.")
        }
        guard self.hasDirectAccessToRoad(address: address) else {
            throw StartInvestmentError.formalProblem(reason: "You cannot build apartment here as this property has no direct access to the public road.")
        }
        let invoice = Invoice(netValue: InvestmentPrice.buildingApartment(storey: storeyAmount), taxPercent: TaxRates.investmentTax)
        // process the transaction
        let transaction = FinancialTransaction(payerID: session.player.id, recipientID: SystemPlayerID.government.rawValue, invoice: invoice)
        if case .failure(let reason) = CentralBank.shared.process(transaction) {
            throw StartInvestmentError.financialTransactionProblem(reason: reason)
        }
        
        let building = ResidentialBuilding(land: land, storeyAmount: storeyAmount)
        self.properties = self.properties.filter { $0.address != address }
        (1...building.storeyAmount).forEach { storey in
            (1...building.numberOfFlatsPerStorey).forEach { flatNo in
                let apartment = Apartment(building, storey: storey, flatNumber: flatNo)
                apartment.monthlyBuildingFee = PriceList.baseApartmentBuildingOwnerFee
                Storage.shared.apartments.append(apartment)
            }
        }
        self.recalculateFeesInTheBuilding(building)
        self.properties.append(building)
        self.saveProperties()
        
        let tile = GameMapTile(address: address, type: .building(size: storeyAmount))
        self.mapManager.map.replaceTile(tile: tile)
        
        let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
        GameEventBus.gameEvents.onNext(updateWalletEvent)

        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
    }
    
    func estimatePrice(_ property: Property) -> Double {
        if let land = property as? Land, let value = self.estimatePriceForLand(land) {
            return value * (1 + self.occupiedSpaceOnMapFactor())
        }
        if let _ = property as? Road {
            return 0.0
        }
        if let building = property as? ResidentialBuilding {
            var basePrice = self.estimatePrice(Land(address: building.address))
            let apartments = Storage.shared.getApartments(address: building.address).filter { $0.ownerID == building.ownerID }
            apartments.forEach { apartment in
                basePrice += self.estimateApartmentValue(apartment)
            }
            return basePrice.rounded(toPlaces: 0)
        }
        Logger.error("RealEstateAgent", "Couldn't estimate value for \(type(of: property)) \(property.id)!")
        return 900000000
    }
    
    func estimateApartmentValue(_ apartment: Apartment) -> Double {
        if let building = self.getProperty(address: apartment.address) as? ResidentialBuilding {
            let investmentCost = InvestmentPrice.buildingApartment(storey: building.storeyAmount)
            let numberOfFlats = Double(building.numberOfFlatsPerStorey * building.storeyAmount)
            let baseValue = (investmentCost/numberOfFlats + PriceList.baseBuildingDeveloperIncomeOnFlatSellPrice) * 1.42
            // TODO: add dependency on neighbourhood
            return (baseValue * building.condition/100 * apartment.condition/100).rounded(toPlaces: 0)
        }
        Logger.error("RealEstateAgent", "Apartment \(apartment.id) is detached from building!")
        return 900000000
    }
    
    func estimateRentFee(_ apartment: Apartment) -> Double {
        if let building = self.getProperty(address: apartment.address) as? ResidentialBuilding {
            return (PriceList.baseApartmentRentalFee * building.condition/100 * apartment.condition/100).rounded(toPlaces: 0)
        }
        return 0.0
    }
    
    private func estimatePriceForLand(_ land: Land) -> Double? {
        // in future add price relation to bus stop
        var startPrice = PriceList.baseLandValue

        for distance in (1...4) {
            for streetAddress in self.mapManager.map.getNeighbourAddresses(to: land.address, radius: distance) {
                if let tile = self.mapManager.map.getTile(address: streetAddress), tile.isStreet() {
                    
                    if distance == 1 {
                        for buildingAddress in self.mapManager.map.getNeighbourAddresses(to: land.address, radius: 1) {
                            if let tile = self.mapManager.map.getTile(address: buildingAddress), tile.isBuilding() {
                                return startPrice * 1.65
                            }
                        }
                        for buildingAddress in self.mapManager.map.getNeighbourAddresses(to: land.address, radius: 2) {
                            if let tile = self.mapManager.map.getTile(address: buildingAddress), tile.isBuilding() {
                                return startPrice * 1.45
                            }
                        }
                    }
                    return startPrice
                }
            }
            startPrice = startPrice * 0.6
        }
        return startPrice
    }
    
    private func recalculateFeesInTheBuilding(_ building: ResidentialBuilding) {
        let apartments = Storage.shared.getApartments(address: building.address)
        
        let baseBuildingMonthlyCosts: Double = 1300 + 1100 * Double(building.storeyAmount)
        let numberOfFlats = Double(building.storeyAmount * 3)
        
        let buildingCostPerFlat = (baseBuildingMonthlyCosts/numberOfFlats + PriceList.baseBuildingDeveloperIncomeOnFlatOwner).rounded(toPlaces: 0)
        
        var income: Double = 0
        var spendings = baseBuildingMonthlyCosts
        apartments.forEach { apartment in
            
            switch apartment.isRented {
                case true:
                    apartment.monthlyRentalFee = self.estimateRentFee(apartment)
                    apartment.monthlyBills = 622
                case false:
                    apartment.monthlyRentalFee = 0
                    apartment.monthlyBills = 280
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
