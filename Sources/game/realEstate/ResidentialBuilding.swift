//
//  ResidentialBuilding.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

struct ResidentialBuilding: Property {
    
    let uuid: String
    var type: String { return "\(self.storeyAmount)-storey Residential Building" }
    let ownerUUID: String
    let address: MapPoint
    let name: String
    let purchaseNetValue: Double
    let investmentsNetValue: Double
    let condition: Double
    let storeyAmount: Int
    let isUnderConstruction: Bool
    let constructionFinishMonth: Int
    let balconies: [ApartmentWindowSide]
    
    var numberOfFlats: Int {
        return 4 * self.storeyAmount
    }
    
    var mapTile: TileType {
        var buildingType = BuildingBalcony.none
        if self.balconies.contains(.eastNorth), self.balconies.contains(.eastSouth) {
            buildingType = .northAndSouthBalcony
        } else if self.balconies.contains(.eastNorth) {
            buildingType = .northBalcony
        } else if self.balconies.contains(.eastSouth) {
            buildingType = .southBalcony
        }
        return .building(size: self.storeyAmount, balcony: buildingType)
    }
    
    init(land: Land, storeyAmount: Int, constructionFinishMonth: Int? = nil, investmentsNetValue: Double = 0, balconies: [ApartmentWindowSide] = []) {
        self.uuid = land.uuid
        self.address = land.address
        self.name = "\(land.name) Apartments"
        self.ownerUUID = land.ownerUUID
        self.purchaseNetValue = land.purchaseNetValue
        self.storeyAmount = storeyAmount
        self.investmentsNetValue = (land.investmentsNetValue + investmentsNetValue).rounded(toPlaces: 0)
        self.condition = 100.0
        self.isUnderConstruction = constructionFinishMonth == nil ? false : true
        self.constructionFinishMonth = constructionFinishMonth ?? 0
        self.balconies = []
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
        self.condition = managedObject.condition
        self.storeyAmount = managedObject.storeyAmount
        self.balconies = managedObject.balconies.components(separatedBy: ",").compactMap{ ApartmentWindowSide(rawValue: $0) }
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
