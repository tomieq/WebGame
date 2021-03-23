//
//  Land.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

class Land: Property, Codable {
    
    var type: String { return "Land property" }
    var ownerID: String?
    var address: [MapPoint]
    var moneyValueWhenBought: Double?
    var currentMoneyValue: Double?
    var mapTiles: [GameMapTile] {
        return [GameMapTile(address: address.first!, type: .soldLand)]
    }
    
    init(address: MapPoint) {
        self.address = [address]
    }


}
