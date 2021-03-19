//
//  RealEstateAgent.swift
//  
//
//  Created by Tomasz Kucharski on 17/03/2021.
//

import Foundation

class RealEstateAgent {
    private let map: GameMap
    
    init(map: GameMap) {
        self.map = map
    }
    
    func putTiles(_ tiles: [GameMapTile]) {
        tiles.forEach {
            self.map.replaceTile(tile: $0)
        }
        let event = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(event)
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
