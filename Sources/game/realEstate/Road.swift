//
//  Road.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class Road: Property, Codable {
    
    let uuid: String
    var type: String { return "Public street" }
    var ownerUUID: String?
    var address: MapPoint
    let name: String
    var purchaseNetValue: Double?
    var investmentsNetValue: Double
    var isUnderConstruction: Bool
    var constructionFinishMonth: Int?
    var accountantID: String?
    
    init(land: Land) {
        self.uuid = land.uuid
        self.address = land.address
        self.name = land.name
        self.ownerUUID = land.ownerUUID
        self.purchaseNetValue = land.purchaseNetValue
        self.investmentsNetValue = (land.investmentsNetValue /*+ ConstructionPriceList.makeRoadCost()*/).rounded(toPlaces: 0)
        self.isUnderConstruction = false
        self.constructionFinishMonth = nil
        self.accountantID = nil
    }
}
