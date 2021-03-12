//
//  GameMap.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation

class GameMap {
    var tiles: [GameMapTile] = []
    
    init() {
        self.tiles.append(GameMapTile(x: 0, y: 0, image: .grass))
        self.tiles.append(GameMapTile(x: 0, y: 1, image: .street(type: .x)))
    }
}

struct GameMapTile {
    let x: Int
    let y: Int
    let image: TileImage
}
