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
    var purchaseNetValue: Double?
    var investmentsNetValue: Double
    var monthlyMaintenanceCost: Double
    var monthlyIncome: Double
    
    init(land: Land) {
        self.address = land.address
        self.name = land.name
        self.ownerID = land.ownerID
        self.purchaseNetValue = land.purchaseNetValue
        self.monthlyMaintenanceCost = 580
        self.monthlyIncome = 0
        self.investmentsNetValue = (land.investmentsNetValue + InvestmentPrice.buildingRoad()).rounded(toPlaces: 0)
    }
}
