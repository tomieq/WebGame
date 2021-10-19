//
//  Land.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

class Land: Property, Codable {
    
    let id: String
    var ownerID: String?
    let address: MapPoint
    let name: String
    var purchaseNetValue: Double?
    var investmentsNetValue: Double
    var isUnderConstruction: Bool
    var constructionFinishMonth: Int?
    var accountantID: String?

    var type: String { return "Land property" }
    var mapTile: GameMapTile {
        return GameMapTile(address: address, type: .soldLand)
    }
    
    init(address: MapPoint) {
        self.id = ""
        self.address = address
        self.name = "\(RandomNameGenerator.randomAdjective.capitalized) \(RandomNameGenerator.randomNoun.capitalized)"
        self.investmentsNetValue = 0
        self.isUnderConstruction = false
        self.constructionFinishMonth = nil
        self.accountantID = nil
    }
    
    init(_ managedObject: LandManagedObject) {
        self.id = managedObject.uuid
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
    }
}
