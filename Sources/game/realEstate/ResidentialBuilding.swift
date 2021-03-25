//
//  ResidentialBuilding.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

class ResidentialBuilding: Property, Codable {
    let id: String
    var type: String { return "\(self.storeyAmount)-storey Residential Building" }
    var ownerID: String?
    let address: MapPoint
    let name: String
    let purchaseNetValue: Double?
    var investmentsNetValue: Double
    var monthlyMaintenanceCost: Double
    var monthlyIncome: Double
    var condition: Double
    
    let storeyAmount: Int
    
    init(land: Land, storeyAmount: Int) {
        self.id = land.id
        self.address = land.address
        self.name = "\(land.name) Apartments"
        self.ownerID = land.ownerID
        self.purchaseNetValue = land.purchaseNetValue
        self.monthlyMaintenanceCost = 0
        self.monthlyIncome = 0
        self.storeyAmount = storeyAmount
        self.investmentsNetValue = (land.investmentsNetValue + InvestmentPrice.buildingApartment(storey: self.storeyAmount)).rounded(toPlaces: 0)
        self.condition = 1.0
        self.updateIncome()
    }
    
    func updateIncome() {
        let apartments = Storage.shared.getApartments(address: self.address)
        var income: Double = 0
        var spendings: Double = 1300 + 1100 * Double(storeyAmount)
        apartments.forEach { apartment in
            if apartment.ownerID == self.ownerID {
                income += apartment.monthlyRentalFee
                spendings += apartment.monthlyBills
            } else {
                apartment.monthlyBuildingFee = 540
                income += apartment.monthlyBuildingFee
            }
        }
        self.monthlyIncome = income.rounded(toPlaces: 0)
        self.monthlyMaintenanceCost = spendings.rounded(toPlaces: 0)
    }
    
}
