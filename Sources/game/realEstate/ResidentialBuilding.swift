//
//  ResidentialBuilding.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

class ResidentialBuilding: Property, Codable {
    var type: String { return "\(self.storeyAmount) storey Apartment" }
    var ownerID: String?
    var address: MapPoint
    let name: String
    var purchaseNetValue: Double?
    var investmentsNetValue: Double
    var monthlyMaintenanceCost: Double
    var monthlyIncome: Double
    
    let storeyAmount: Int
    
    init(land: Land, storeyAmount: Int) {
        self.address = land.address
        self.name = "\(land.name) Apartments"
        self.ownerID = land.ownerID
        self.purchaseNetValue = land.purchaseNetValue
        self.monthlyMaintenanceCost = 1300 + 1100 * Double(storeyAmount)
        self.monthlyIncome = 0
        self.storeyAmount = storeyAmount
        self.investmentsNetValue = (land.investmentsNetValue + InvestmentPrice.buildingApartment(storey: self.storeyAmount)).rounded(toPlaces: 0)
    }
    
}
