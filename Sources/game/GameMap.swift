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
    
    init() {
        self.width = 25
        self.height = 25
        self.scale = 0.35
        let parser = GameMapFileParser()
        self.tiles = parser.loadStreets("maps/roadMap1")
    }
    
    
}

struct GameMapTile {
    let x: Int
    let y: Int
    let image: TileImage
}
