//
//  RealEstateAgent.swift
//  
//
//  Created by Tomasz Kucharski on 17/03/2021.
//

import Foundation

class RealEstateAgent {
    private let map: GameMap
    private var properties: [Property]
    
    init(map: GameMap) {
        self.map = map
        self.properties = []
        
        Storage.shared.landProperties.forEach { land in
            self.properties.append(land)
            let tile = GameMapTile(address: land.address.first!, type: .soldLand)
            self.map.replaceTile(tile: tile)
        }
    }
    
    func isForSale(address: MapPoint) -> Bool {
        return self.map.getTile(address: address) == nil
    }
    
    func getProperty(address: MapPoint) -> Property? {
        return self.properties.first { $0.address.contains(address) }
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
        }
        property.mapTiles.forEach {
            self.map.replaceTile(tile: $0)
        }
        
        let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
        GameEventBus.gameEvents.onNext(updateWalletEvent)
        
        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
        
        let announcementEvent = GameEvent(playerSession: nil, action: .notification(UINotification(text: "New transaction on the market. Player \(session.player.login) has just bought property `\(property.name)`", level: .info, duration: 10)))
        GameEventBus.gameEvents.onNext(announcementEvent)
    }
    
    func evaluatePrice(_ property: Property) -> Double? {
        if let land = property as? Land, let value = self.evaluatePriceForLand(land) {
            return value * (1 + self.occupiedSpaceOnMapFactor())
        }
        return nil
    }
    
    private func evaluatePriceForLand(_ land: Land) -> Double? {
        // in future add price relation to bus stop
        var startPrice: Double = 80000

        for distance in (1...4) {
            for streetAddress in self.map.getNeighbourAddresses(to: land.address.first!, radius: distance) {
                if let tile = self.map.getTile(address: streetAddress), tile.isStreet() {
                    
                    if distance == 1 {
                        for buildingAddress in self.map.getNeighbourAddresses(to: land.address.first!, radius: 1) {
                            if let tile = self.map.getTile(address: buildingAddress), tile.isBuilding() {
                                return startPrice * 1.65
                            }
                        }
                        for buildingAddress in self.map.getNeighbourAddresses(to: land.address.first!, radius: 2) {
                            if let tile = self.map.getTile(address: buildingAddress), tile.isBuilding() {
                                return startPrice * 1.45
                            }
                        }
                    }
                    return startPrice
                }
            }
            startPrice = startPrice * 0.7
        }
        return startPrice
    }
    
    func occupiedSpaceOnMapFactor() -> Double {
        return Double(self.map.gameTiles.count) / Double(self.map.width * self.map.height)
    }
 }


enum BuyPropertyError: Error {
    case propertyNotForSale
    case problemWithPrice
    case notEnoughMoneyInWallet
}
