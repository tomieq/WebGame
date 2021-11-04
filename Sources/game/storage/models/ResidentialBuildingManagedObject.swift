//
//  ResidentialBuildingManagedObject.swift
//  
//
//  Created by Tomasz Kucharski on 19/10/2021.
//

import Foundation

class ResidentialBuildingManagedObject: Codable {
    
    let uuid: String
    var ownerUUID: String
    let x: Int
    let y: Int
    let name: String
    var purchaseNetValue: Double
    var investmentsNetValue: Double
    var isUnderConstruction: Bool
    var constructionFinishMonth: Int
    var condition: Double
    let storeyAmount: Int

    init(_ building: ResidentialBuilding) {
        self.uuid = UUID().uuidString
        self.ownerUUID = building.ownerUUID
        self.x = building.address.x
        self.y = building.address.y
        self.name = building.name
        self.purchaseNetValue = building.purchaseNetValue
        self.investmentsNetValue = building.investmentsNetValue
        self.isUnderConstruction = building.isUnderConstruction
        self.constructionFinishMonth = building.constructionFinishMonth
        self.condition = building.condition
        self.storeyAmount = building.storeyAmount
    }
}
