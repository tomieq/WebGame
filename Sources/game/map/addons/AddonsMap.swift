//
//  AddonsMap.swift
//  
//
//  Created by Tomasz Kucharski on 14/02/2022.
//

import Foundation

protocol AddonsMapDelegate {
    func reloadAddonsMap()
}

struct AddonMapTile {
    let address: MapPoint
    let type: AddonTileType
}

class AddonsMap {
    private var addonTiles: [MapPoint:AddonMapTile] = [:]
    private var gameMap: GameMap
    var delegate: AddonsMapDelegate?
    var tiles: [AddonMapTile] {
        return Array(self.addonTiles.values)
    }
    
    init(gameMap: GameMap) {
        self.gameMap = gameMap
        
        self.syncMapTiles()
    }
    
    private func syncMapTiles() {
        self.addonTiles = [:]
        for tile in self.gameMap.tiles {
            let address = tile.address
            switch tile.type {
            case .parking(let parkingType):
                self.addonTiles[address] = AddonMapTile(address: address, type: .carsOnParking(direction: parkingType.direction, size: 10))
            default:
                break
            }
        }
        self.delegate?.reloadAddonsMap()
    }
    
    func constructionFinished(_ types: [ConstructionType]) {
        if types.contains(.parking) {
            self.syncMapTiles()
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
