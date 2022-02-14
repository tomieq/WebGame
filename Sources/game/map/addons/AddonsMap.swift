//
//  AddonsMap.swift
//  
//
//  Created by Tomasz Kucharski on 14/02/2022.
//

import Foundation



struct AddonMapTile {
    let address: MapPoint
    let type: AddonTileType
}

class AddonsMap {
    private var addonTiles: [MapPoint:AddonMapTile] = [:]
    private var gameMap: GameMap
    var tiles: [AddonMapTile] {
        return Array(self.addonTiles.values)
    }
    
    init(gameMap: GameMap) {
        self.gameMap = gameMap
        
        for tile in self.gameMap.tiles {
            let address = tile.address
            switch tile.type {
            case .parking(let parkingType):
                self.addonTiles[address] = AddonMapTile(address: address, type: .carsOnParking(direction: parkingType.direction, size: 10))
            default:
                break
            }
        }
    }
}

fileprivate extension ParkingType {
    var direction: CarsOnParkingDirection {
        switch self {
            
        case .bottomConnection:
            return .Y
        case .topConnection:
            return .Y
        case .leftConnection:
            return .X
        case .rightConnection:
            return .X
        case .X:
            return .X
        case .Y:
            return .Y
        }
    }
}
