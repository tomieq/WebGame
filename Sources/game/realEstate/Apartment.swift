//
//  Condo.swift
//
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

enum ApartmentWindowSide: String, CaseIterable {
    case north
    case northEast
    case east
    case southEast
    case south
    case southWest
    case west
    case northWest

    var name: String {
        switch self {
        case .east:
            return "East"
        case .southEast:
            return "South-East"
        case .northEast:
            return "North-East"
        case .west:
            return "West"
        case .southWest:
            return "South West"
        case .northWest:
            return "North West"
        case .north:
            return "North"
        case .south:
            return "South"
        }
    }
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

    init(ownerUUID: String, address: MapPoint, windowSide: ApartmentWindowSide, hasBalcony: Bool, storey: Int, condition: Double = 1.0) {
        self.uuid = ""
        self.ownerUUID = ownerUUID
        self.address = address
        self.purchaseNetValue = 0
        self.investmentsNetValue = 0
        self.windowSide = windowSide
        self.livingArea = 54
        self.numberOfBedrooms = 2
        self.hasBalcony = hasBalcony
        self.storey = storey
        self.isRented = false
        self.condition = min(1, max(0, condition))
    }

    init(_ managedObject: ApartmentManagedObject) {
        self.uuid = managedObject.uuid
        self.ownerUUID = managedObject.ownerUUID
        self.address = MapPoint(x: managedObject.x, y: managedObject.y)
        self.purchaseNetValue = managedObject.purchaseNetValue
        self.investmentsNetValue = managedObject.investmentsNetValue
        self.windowSide = ApartmentWindowSide(rawValue: managedObject.windowSide) ?? .northEast
        self.livingArea = managedObject.livingArea
        self.numberOfBedrooms = managedObject.numberOfBedrooms
        self.hasBalcony = managedObject.hasBalcony
        self.storey = managedObject.storey
        self.isRented = managedObject.isRented
        self.condition = managedObject.condition
    }
}
