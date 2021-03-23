//
//  Road.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class Road: Property, Codable {
    
    var type: String { return "Public street" }
    var ownerID: String?
    var address: MapPoint
    let name: String
    var transactionNetValue: Double?
    var monthlyMaintenanceCost: Double
    
    init(land: Land) {
        self.address = land.address
        self.name = land.name
        self.ownerID = land.ownerID
        self.transactionNetValue = land.transactionNetValue
        self.monthlyMaintenanceCost = 580
    }
}
