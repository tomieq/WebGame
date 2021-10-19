//
//  Road.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

struct Road: Property, Codable {
    
    let uuid: String
    var type: String { return "Public street" }
    let ownerUUID: String?
    let address: MapPoint
    let name: String
    let purchaseNetValue: Double?
    let investmentsNetValue: Double
    let isUnderConstruction: Bool
    let constructionFinishMonth: Int?
    let accountantID: String?
    
    init(land: Land, constructionFinishMonth: Int? = nil) {
        self.uuid = land.uuid
        self.address = land.address
        self.name = land.name
        self.ownerUUID = land.ownerUUID
        self.purchaseNetValue = land.purchaseNetValue
        self.investmentsNetValue = (land.investmentsNetValue /*+ ConstructionPriceList.makeRoadCost()*/).rounded(toPlaces: 0)
        self.isUnderConstruction = true
        self.constructionFinishMonth = constructionFinishMonth
        self.accountantID = nil
    }
    
    init(_ managedObject: RoadManagedObject) {
        self.uuid = managedObject.uuid
        self.ownerUUID = managedObject.ownerUUID
        self.address = MapPoint(x: managedObject.x, y: managedObject.y)
        self.name = managedObject.name
        self.purchaseNetValue = managedObject.purchaseNetValue
        self.investmentsNetValue = managedObject.investmentsNetValue
        self.isUnderConstruction = managedObject.isUnderConstruction
        self.constructionFinishMonth = managedObject.constructionFinishMonth
        self.accountantID = managedObject.accountantID
    }
}

struct RoadMutation {
    let uuid: String
    let attributes: [LandMutation.Attribute]
    
    enum Attribute {
        case isUnderConstruction(Bool)
        case constructionFinishMonth(Int)
        case ownerUUID(String)
        case purchaseNetValue(Double)
    }
}
