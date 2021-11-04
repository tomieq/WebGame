//
//  Land.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

struct Land: Property {
    
    let uuid: String
    let ownerUUID: String
    let address: MapPoint
    let name: String
    let purchaseNetValue: Double
    let investmentsNetValue: Double
    let isUnderConstruction: Bool
    let constructionFinishMonth: Int
    let accountantID: String?

    var type: String { return "Land property" }
    
    init(address: MapPoint, name: String? = nil, ownerUUID: String = SystemPlayer.government.uuid, purchaseNetValue: Double = 0, investmentsNetValue: Double = 0) {
        self.uuid = ""
        self.ownerUUID = ownerUUID
        self.address = address
        self.name = name ?? RandomNameGenerator.getName()
        self.investmentsNetValue = investmentsNetValue
        self.isUnderConstruction = false
        self.constructionFinishMonth = 0
        self.accountantID = nil
        self.purchaseNetValue = purchaseNetValue
    }
    
    init(_ managedObject: LandManagedObject) {
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

struct LandMutation {
    let uuid: String
    let attributes: [LandMutation.Attribute]
    
    enum Attribute {
        case isUnderConstruction(Bool)
        case constructionFinishMonth(Int)
        case ownerUUID(String)
        case purchaseNetValue(Double)
        case investments(Double)
    }
}
