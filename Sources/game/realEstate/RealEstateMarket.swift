//
//  RealEstateMarket.swift
//  
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation

enum RealEstateMarketError: Error {
    case propertyDoesNotExist
}

class RealEstateMarket {
    private let gameMap: GameMap
    
    init(gameMap: GameMap) {
        self.gameMap = gameMap
    }
    
    func createOffer(address: MapPoint, netValue: Double) throws {
        guard self.gameMap.isAddressOnMap(address) else {
            throw RealEstateMarketError.propertyDoesNotExist
        }
    }
}
