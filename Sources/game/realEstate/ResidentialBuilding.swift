//
//  ResidentialBuilding.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

struct ResidentialBuilding: Property, Codable {
    
    let uuid: String
    var type: String { return "\(self.storeyAmount)-storey Residential Building" }
    let ownerUUID: String
    let address: MapPoint
    let name: String
    let purchaseNetValue: Double
    let investmentsNetValue: Double
    let condition: Double
    let numberOfFlatsPerStorey = 4
    let storeyAmount: Int
    let isUnderConstruction: Bool
    let constructionFinishMonth: Int
    let accountantID: String?
    
    var numberOfFlats: Int {
        return self.numberOfFlatsPerStorey * self.storeyAmount
    }
    
    init(land: Land, storeyAmount: Int, constructionFinishMonth: Int? = nil, investmentsNetValue: Double = 0) {
        self.uuid = land.uuid
        self.address = land.address
        self.name = "\(land.name) Apartments"
        self.ownerUUID = land.ownerUUID
        self.purchaseNetValue = land.purchaseNetValue
        self.storeyAmount = storeyAmount
        self.investmentsNetValue = (land.investmentsNetValue + investmentsNetValue).rounded(toPlaces: 0)
        self.condition = 100.0
        self.isUnderConstruction = constructionFinishMonth == nil ? false : true
        self.accountantID = land.accountantID
        self.constructionFinishMonth = constructionFinishMonth ?? 0
    }
    
    init(_ managedObject: ResidentialBuildingManagedObject) {
        self.uuid = managedObject.uuid
        self.ownerUUID = managedObject.ownerUUID
        self.address = MapPoint(x: managedObject.x, y: managedObject.y)
        self.name = managedObject.name
        self.purchaseNetValue = managedObject.purchaseNetValue
        self.investmentsNetValue = managedObject.investmentsNetValue
        self.isUnderConstruction = managedObject.isUnderConstruction
        self.constructionFinishMonth = managedObject.constructionFinishMonth
        self.accountantID = managedObject.accountantID
        self.condition = managedObject.condition
        self.storeyAmount = managedObject.storeyAmount
    }
}

struct ResidentialBuildingMutation {
    let uuid: String
    let attributes: [ResidentialBuildingMutation.Attribute]
    
    enum Attribute {
        case isUnderConstruction(Bool)
        case constructionFinishMonth(Int)
        case ownerUUID(String)
        case purchaseNetValue(Double)
        case investmentsNetValue(Double)
    }
}
