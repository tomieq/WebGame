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
    var address: MapPoint
    let name: String
    var transactionNetValue: Double?
    var monthlyMaintenanceCost: Double
    var monthlyIncome: Double
    var mapTile: GameMapTile {
        return GameMapTile(address: address, type: .soldLand)
    }
    
    init(address: MapPoint) {
        self.address = address
        self.name = "\(RandomNameGenerator.randomAdjective.capitalized) \(RandomNameGenerator.randomNoun.capitalized)"
        self.monthlyMaintenanceCost = 100
        self.monthlyIncome = 0
    }
}
