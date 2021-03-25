//
//  Apartment.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

class Apartment: Codable {
    
    let id: String
    var type: String { return "Apartment" }
    let name: String
    let flatNumber: Int
    let storey: Int
    let address: MapPoint
    var ownerID: String?
    var monthlyBuildingFee: Double
    var monthlyRentalFee: Double
    var monthlyBills: Double
    var isRented: Bool
    var condition: Double
    
    init(_ building: ResidentialBuilding, storey: Int, flatNumber: Int) {
        self.id = UUID().uuidString
        self.storey = storey
        self.flatNumber = flatNumber
        self.ownerID = building.ownerID
        self.name = "Apartment \(storey).\(flatNumber) at \(building.name)"
        self.address = building.address
        self.monthlyBuildingFee = 0
        self.monthlyRentalFee = 0
        self.monthlyBills = 622
        self.isRented = false
        // condition varies from 0 to 1, 1 means 100%
        self.condition = 1.0
    }
}
