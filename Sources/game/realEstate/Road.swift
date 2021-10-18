//
//  Road.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class Road: Property, Codable {
    
    let id: String
    var type: String { return "Public street" }
    var ownerID: String?
    var address: MapPoint
    let name: String
    var purchaseNetValue: Double?
    var investmentsNetValue: Double
    var monthlyMaintenanceCost: Double
    var monthlyIncome: Double
    var isUnderConstruction: Bool
    var constructionFinishMonth: Int?
    var accountantID: String?
    
    init(land: Land) {
        self.id = land.id
        self.address = land.address
        self.name = land.name
        self.ownerID = land.ownerID
        self.purchaseNetValue = land.purchaseNetValue
        self.monthlyMaintenanceCost = 580
        self.monthlyIncome = 0
        self.investmentsNetValue = (land.investmentsNetValue /*+ ConstructionPriceList.makeRoadCost()*/).rounded(toPlaces: 0)
        self.isUnderConstruction = false
        self.constructionFinishMonth = nil
        self.accountantID = nil
    }
}
