//
//  LandManagedObject.swift
//  
//
//  Created by Tomasz Kucharski on 19/10/2021.
//

import Foundation

class LandManagedObject: Codable {

    let uuid: String
    var ownerUUID: String
    let x: Int
    let y: Int
    let name: String
    var purchaseNetValue: Double
    var investmentsNetValue: Double
    var isUnderConstruction: Bool
    var constructionFinishMonth: Int
    var accountantID: String?

    init(_ land: Land) {
        self.uuid = UUID().uuidString
        self.ownerUUID = land.ownerUUID
        self.x = land.address.x
        self.y = land.address.y
        self.name = land.name
        self.purchaseNetValue = land.purchaseNetValue
        self.investmentsNetValue = land.investmentsNetValue
        self.isUnderConstruction = land.isUnderConstruction
        self.constructionFinishMonth = land.constructionFinishMonth
        self.accountantID = land.accountantID
    }
}
