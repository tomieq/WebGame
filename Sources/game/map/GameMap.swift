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
    private var tiles: [GameMapTile] = []
    var gameTiles: [GameMapTile] {
        get {
            return self.tiles
        }
    }
    
    init(width: Int, height: Int, scale: Double, path: String) {
        self.width = width
        self.height = height
        self.scale = scale
        let parser = GameMapFileParser()
        self.tiles = parser.loadStreets(path)
    }
    
    func getTile(address: MapPoint) -> GameMapTile? {
        return self.tiles.first{ $0.address == address }
    }
    
    func replaceTile(tile: GameMapTile) {
        self.tiles = self.tiles.filter { $0.address != tile.address }
        self.tiles.append(tile)
    }
}

struct GameMapTile {
    let address: MapPoint
    let type: TileType
}
