//
//  ApartmentManagedObject.swift
//  
//
//  Created by Tomasz Kucharski on 10/11/2021.
//

import Foundation

class ApartmentManagedObject {
    
    let uuid: String
    var ownerUUID: String
    let x: Int
    let y: Int
    var purchaseNetValue: Double
    var investmentsNetValue: Double
    
    let windowSide: String
    let livingArea: Int
    let numberOfBedrooms: Int
    let hasBalcony: Bool
    
    let storey: Int
    var isRented: Bool
    var condition: Double
    
    init(_ apartment: Apartment) {
        self.uuid = UUID().uuidString
        self.ownerUUID = apartment.ownerUUID
        self.x = apartment.address.x
        self.y = apartment.address.y
        self.purchaseNetValue = apartment.purchaseNetValue
        self.investmentsNetValue = apartment.investmentsNetValue
        self.windowSide = apartment.windowSide.rawValue
        self.livingArea = apartment.livingArea
        self.numberOfBedrooms = apartment.numberOfBedrooms
        self.hasBalcony = apartment.hasBalcony
        self.storey = apartment.storey
        self.isRented = apartment.isRented
        self.condition = apartment.condition
    }
    
}
