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
    var tiles: [GameMapTile] = []
    
    init(width: Int, height: Int, scale: Double, path: String) {
        self.width = width
        self.height = height
        self.scale = scale
        let parser = GameMapFileParser()
        self.tiles = parser.loadStreets(path)
    }
    
    
}

struct GameMapTile {
    let address: MapPoint
    let type: TileType
}
