//
//  GameMap.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation

class GameMap {
    
    let width: Int
    let height: Int
    let scale: Double
    private var gameTiles: [MapPoint:GameMapTile]
    var tiles: [GameMapTile] {
        return Array(self.gameTiles.values)
    }
    
    init(width: Int, height: Int, scale: Double) {
        self.width = width
        self.height = height
        self.scale = scale
        self.gameTiles = [:]
    }
    
    func setTiles(_ tiles: [GameMapTile]) {
        self.gameTiles = [:]
        for tile in tiles {
            self.gameTiles[tile.address] = tile
        }
    }
    
    func getTile(address: MapPoint) -> GameMapTile? {
        return self.gameTiles[address]
    }
    
    func replaceTile(tile: GameMapTile) {
        self.gameTiles[tile.address] = tile
    }
    
    func getNeighbourAddresses(to address: MapPoint, radius: Int) -> [MapPoint] {
        guard self.isAddressOnMap(address) else { return [] }
        guard radius > 0 else { return [] }

        var points: [MapPoint] = []
        let xMin = address.x - radius
        let xMax = address.x + radius
        let yMin = address.y - radius
        let yMax = address.y + radius
        for x in (xMin...xMax) {
            points.append(MapPoint(x: x, y: yMin))
            points.append(MapPoint(x: x, y: yMax))
        }
        for y in ((yMin + 1)...(yMax - 1)) {
            points.append(MapPoint(x: xMin, y: y))
            points.append(MapPoint(x: xMax, y: y))
        }
        return points.filter { self.isAddressOnMap($0) }
    }
    
    func isAddressOnMap(_ address: MapPoint) -> Bool {
        return address.x >= 0 && address.x < self.width && address.y >= 0 && address.y < self.height
    }
}

struct GameMapTile {
    let address: MapPoint
    let type: TileType
}

extension GameMapTile {
    func isStreet() -> Bool {
        if case .street(_) = self.type {
            return true
        }
        return false
    }

    func isBuilding() -> Bool {
        if case .building = self.type {
            return true
        }
        if case .buildingUnderConstruction = self.type {
            return true
        }
        return false
    }
    
    func isAntenna() -> Bool {
        if case .btsAntenna = self.type {
            return true
        }
        return false
    }
}
