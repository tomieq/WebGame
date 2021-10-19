//
//  ResidentialBuilding.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

class ResidentialBuilding: Property, Codable {
    
    let uuid: String
    var type: String { return "\(self.storeyAmount)-storey Residential Building" }
    var ownerUUID: String?
    let address: MapPoint
    let name: String
    var purchaseNetValue: Double?
    var investmentsNetValue: Double
    var condition: Double
    var numberOfFlatsPerStorey = 4
    let storeyAmount: Int
    var isUnderConstruction: Bool
    var constructionFinishMonth: Int?
    var accountantID: String?
    
    var numberOfFlats: Int {
        return self.numberOfFlatsPerStorey * self.storeyAmount
    }
    
    init(land: Land, storeyAmount: Int) {
        self.uuid = land.uuid
        self.address = land.address
        self.name = "\(land.name) Apartments"
        self.ownerUUID = land.ownerUUID
        self.purchaseNetValue = land.purchaseNetValue
        self.storeyAmount = storeyAmount
        self.investmentsNetValue = (land.investmentsNetValue /*+ ConstructionPriceList.makeResidentialBuildingCost(storey: self.storeyAmount)*/).rounded(toPlaces: 0)
        self.condition = 100.0
        self.isUnderConstruction = false
        self.accountantID = land.accountantID
    }
    
}
