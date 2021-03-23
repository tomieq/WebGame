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
    }
    
    func isForSale(address: MapPoint) -> Bool {
        return self.mapManager.map.getTile(address: address) == nil
    }
    
    func getProperty(address: MapPoint) -> Property? {
        return self.properties.first { $0.address == address }
    }
    
    private func saveProperties() {
        Storage.shared.landProperties = self.properties.compactMap { $0 as? Land }
        Storage.shared.roadProperties = self.properties.compactMap { $0 as? Road }
    }
    
    func buyProperty(address: MapPoint, session: PlayerSession) throws {
        
        guard self.isForSale(address: address) else {
            throw BuyPropertyError.propertyNotForSale
        }
        let property = Land(address: address)
        guard let price = self.estimatePrice(property) else {
            throw BuyPropertyError.problemWithPrice
        }
        let transactionCost = TransactionCost(propertyValue: price)
        guard session.player.wallet > transactionCost.total else {
            throw BuyPropertyError.notEnoughMoneyInWallet
        }
        
        // proceed the transaction
        session.player.takeMoney(transactionCost.total)
        property.ownerID = session.player.id
        property.transactionNetValue = transactionCost.propertyValue
        
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
    
    func buildRoad(address: MapPoint, session: PlayerSession) throws {
        
        guard let land = (self.properties.first { $0.address == address}) as? Land else {
            throw StartInvestmentError.invalidPropertyType
        }
        guard land.ownerID == session.player.id else {
            throw StartInvestmentError.invalidOwner
        }
        let investmentCost = InvestmentCost(investmentValue: InvestmentPrice.buildingRoad)
        guard session.player.wallet > investmentCost.total else {
            throw StartInvestmentError.notEnoughMoneyInWallet
        }
        let road = Road(land: land)
        self.properties = self.properties.filter { $0.address != address }
        self.properties.append(road)
        self.saveProperties()
        
        Storage.shared.roadProperties.append(road)
        self.mapManager.addStreet(address: address)
        
        session.player.takeMoney(investmentCost.total)
        let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
        GameEventBus.gameEvents.onNext(updateWalletEvent)

        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
    }
    
    func estimatePrice(_ property: Property) -> Double? {
        if let land = property as? Land, let value = self.estimatePriceForLand(land) {
            return value * (1 + self.occupiedSpaceOnMapFactor())
        }
        if let road = property as? Road {
            return 0.0
        }
        return nil
    }
    
    private func estimatePriceForLand(_ land: Land) -> Double? {
        // in future add price relation to bus stop
        var startPrice: Double = 90000

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
    
    func occupiedSpaceOnMapFactor() -> Double {
        return Double(self.mapManager.map.tiles.count) / Double(self.mapManager.map.width * self.mapManager.map.height)
    }
 }


enum BuyPropertyError: Error {
    case propertyNotForSale
    case problemWithPrice
    case notEnoughMoneyInWallet
}

enum StartInvestmentError: Error {
    case invalidOwner
    case invalidPropertyType
    case notEnoughMoneyInWallet
}
