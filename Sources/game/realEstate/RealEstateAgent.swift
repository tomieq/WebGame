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
    
    func buyProperty(address: MapPoint, session: PlayerSession) throws {
        
        guard self.isForSale(address: address) else {
            throw BuyPropertyError.propertyNotForSale
        }
        let property = Land(address: address)
        guard let price = self.evaluatePrice(property) else {
            throw BuyPropertyError.problemWithPrice
        }
        let transactionCosts = TransactionCosts(propertyValue: price)
        guard session.player.wallet > transactionCosts.total else {
            throw BuyPropertyError.notEnoughMoneyInWallet
        }
        
        // proceed the transaction
        session.player.wallet = (session.player.wallet - transactionCosts.propertyValue).rounded(toPlaces: 0)
        property.ownerID = session.player.id
        property.transactionNetValue = transactionCosts.propertyValue
        
        self.properties.append(property)
        if let land = property as? Land {
            Storage.shared.landProperties.append(land)
            self.mapManager.map.replaceTile(tile: land.mapTile)
        }
        
        let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
        GameEventBus.gameEvents.onNext(updateWalletEvent)
        
        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
        
        let announcementEvent = GameEvent(playerSession: nil, action: .notification(UINotification(text: "New transaction on the market. Player \(session.player.login) has just bought property `\(property.name)`", level: .info, duration: 10)))
        GameEventBus.gameEvents.onNext(announcementEvent)
    }
    
    func buildRoad(address: MapPoint, session: PlayerSession) {
        
        guard let land = (self.properties.first { $0.address == address}) as? Land else {
            fatalError("Not a Land")
        }
        guard land.ownerID == session.player.id else {
            fatalError("Not his property")
        }
        let road = Road(land: land)
        self.properties = self.properties.filter { $0.address != address }
        self.properties.append(road)
        Storage.shared.roadProperties.append(road)
        self.mapManager.addStreet(address: address)
        
        session.player.wallet = (session.player.wallet - 410000).rounded(toPlaces: 0)
        let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
        GameEventBus.gameEvents.onNext(updateWalletEvent)

        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
    }
    
    func evaluatePrice(_ property: Property) -> Double? {
        if let land = property as? Land, let value = self.evaluatePriceForLand(land) {
            return value * (1 + self.occupiedSpaceOnMapFactor())
        }
        return nil
    }
    
    private func evaluatePriceForLand(_ land: Land) -> Double? {
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
