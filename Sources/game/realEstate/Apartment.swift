//
//  Apartment.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

class Apartment: Property, Codable {
    
    let id: String
    var type: String { return "Apartment" }
    var name: String
    var ownerID: String?
    var address: MapPoint
    var purchaseNetValue: Double?
    var investmentsNetValue: Double
    // fee paid to the building owner
    var monthlyBuildingFee: Double
    // monthlyMaintenanceCost for flat are all the basic bills
    var monthlyMaintenanceCost: Double
    // monthly income is the money the owner takes for rental
    var monthlyIncome: Double
    var isRented: Bool
    var flatNumber: Int
    var storey: Int
    
    init(_ building: ResidentialBuilding, storey: Int, flatNumber: Int) {
        self.id = UUID().uuidString
        self.storey = storey
        self.flatNumber = flatNumber
        self.name = "Apartment \(storey).\(flatNumber) at \(building.name)"
        self.address = building.address
        self.investmentsNetValue = 0
        // building owner and flat owner is the same player fee is 0
        self.monthlyBuildingFee = 0
        self.monthlyMaintenanceCost = 622
        self.monthlyIncome = 0
        self.ownerID = building.ownerID
        self.isRented = false
    }
}
