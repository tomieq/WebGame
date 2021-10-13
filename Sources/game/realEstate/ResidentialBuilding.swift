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
    var purchaseNetValue: Double?
    var investmentsNetValue: Double
    var monthlyMaintenanceCost: Double
    var monthlyIncome: Double
    var condition: Double
    let numberOfFlatsPerStorey = 4
    let storeyAmount: Int
    var isUnderConstruction: Bool
    var constructionFinishMonth: Int?
    
    var numberOfFlats: Int {
        return self.numberOfFlatsPerStorey * self.storeyAmount
    }
    
    init(land: Land, storeyAmount: Int) {
        self.id = land.id
        self.address = land.address
        self.name = "\(land.name) Apartments"
        self.ownerID = land.ownerID
        self.purchaseNetValue = land.purchaseNetValue
        self.monthlyMaintenanceCost = land.monthlyMaintenanceCost
        self.monthlyIncome = 0
        self.storeyAmount = storeyAmount
        self.investmentsNetValue = (land.investmentsNetValue + InvestmentPrice.buildingApartment(storey: self.storeyAmount)).rounded(toPlaces: 0)
        self.condition = 100.0
        self.isUnderConstruction = false
    }
    
}
