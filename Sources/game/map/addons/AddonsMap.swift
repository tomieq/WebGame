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
    var tiles: [AddonMapTile] {
        return Array(self.addonTiles.values)
    }
}
