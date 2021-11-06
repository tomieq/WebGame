//
//  Parking.swift
//  
//
//  Created by Tomasz Kucharski on 04/11/2021.
//

import Foundation

struct Parking: Property {
    
    let uuid: String
    var type: String { return "Parking lot" }
    let ownerUUID: String
    let address: MapPoint
    let name: String
    let purchaseNetValue: Double
    let investmentsNetValue: Double
    let isUnderConstruction: Bool
    let constructionFinishMonth: Int
    let insurance: ParkingInsurance
    let security: ParkingSecurity
    let advertising: ParkingAdvertising
    let trustLevel: Double
    
    init(land: Land, constructionFinishMonth: Int? = nil, investmentsNetValue: Double = 0, trustLevel: Double = 1.0) {
        self.uuid = land.uuid
        self.address = land.address
        self.name = "\(land.name) Parking lot"
        self.ownerUUID = land.ownerUUID
        self.purchaseNetValue = land.purchaseNetValue
        self.investmentsNetValue = (land.investmentsNetValue + investmentsNetValue).rounded(toPlaces: 0)
        self.isUnderConstruction = constructionFinishMonth == nil ? false: true
        self.constructionFinishMonth = constructionFinishMonth ?? 0
        self.insurance = .none
        self.security = .none
        self.advertising = .none
        self.trustLevel = min(max(trustLevel, 0), 1)
    }
    
    init(_ managedObject: ParkingManagedObject) {
        self.uuid = managedObject.uuid
        self.ownerUUID = managedObject.ownerUUID
        self.address = MapPoint(x: managedObject.x, y: managedObject.y)
        self.name = managedObject.name
        self.purchaseNetValue = managedObject.purchaseNetValue
        self.investmentsNetValue = managedObject.investmentsNetValue
        self.isUnderConstruction = managedObject.isUnderConstruction
        self.constructionFinishMonth = managedObject.constructionFinishMonth
        self.insurance = ParkingInsurance(rawValue: managedObject.insurance) ?? .none
        self.security = ParkingSecurity(rawValue: managedObject.security) ?? .none
        self.advertising = ParkingAdvertising(rawValue: managedObject.advertising) ?? .none
        self.trustLevel = managedObject.trustLevel
    }
}

struct ParkingMutation {
    let uuid: String
    let attributes: [ParkingMutation.Attribute]
    
    enum Attribute {
        case isUnderConstruction(Bool)
        case constructionFinishMonth(Int)
        case ownerUUID(String)
        case purchaseNetValue(Double)
        case investments(Double)
        case insurance(ParkingInsurance)
        case security(ParkingSecurity)
        case advertising(ParkingAdvertising)
        case trustLevel(Double)
    }
}
