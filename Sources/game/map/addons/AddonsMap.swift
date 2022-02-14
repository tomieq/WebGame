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
    }
}
