//
//  Condo.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

enum ApartmentWindowSide {
    case eastSouth
    case eastNorth
    case westSouth
    case westNorth
}

struct Apartment {

    let uuid: String
    var type: String { return "\(self.livingArea)m² Apartment" }
    let ownerUUID: String
    let address: MapPoint
    let purchaseNetValue: Double
    let investmentsNetValue: Double
    
    let windowSide: ApartmentWindowSide
    let livingArea: Int
    let numberOfBedrooms: Int
    let hasBalcony: Bool
    
    let storey: Int
    let isRented: Bool
    let condition: Double
    
    init(_ managedObject: ApartmentManagedObject) {
        self.uuid = managedObject.uuid
        self.ownerUUID = managedObject.ownerUUID
        self.address = MapPoint(x: managedObject.x, y: managedObject.y)
        self.purchaseNetValue = managedObject.purchaseNetValue
        self.investmentsNetValue = managedObject.investmentsNetValue
        self.windowSide = managedObject.windowSide
        self.livingArea = managedObject.livingArea
        self.numberOfBedrooms = managedObject.numberOfBedrooms
        self.hasBalcony = managedObject.hasBalcony
        self.storey = managedObject.storey
        self.isRented = managedObject.isRented
        self.condition = managedObject.condition
    }
}
