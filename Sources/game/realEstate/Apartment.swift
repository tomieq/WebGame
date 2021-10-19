//
//  Apartment.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

class Apartment: Codable {
    
    let uuid: String
    var type: String { return "Apartment" }
    let name: String
    let flatNumber: Int
    let storey: Int
    let address: MapPoint
    var ownerUUID: String?
    var isRented: Bool
    var condition: Double
    
    init(_ building: ResidentialBuilding, storey: Int, flatNumber: Int) {
        self.uuid = UUID().uuidString
        self.storey = storey
        self.flatNumber = flatNumber
        self.ownerUUID = building.ownerUUID
        self.name = "Apartment \(storey).\(flatNumber) at \(building.name)"
        self.address = building.address
        self.isRented = false
        // condition varies from 0 to 100%
        self.condition = 100.0
    }
}
