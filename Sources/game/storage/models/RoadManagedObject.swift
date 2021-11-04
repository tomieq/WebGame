//
//  RoadManagedObject.swift
//  
//
//  Created by Tomasz Kucharski on 19/10/2021.
//

import Foundation

class RoadManagedObject: Codable {
    
    let uuid: String
    var ownerUUID: String
    let x: Int
    let y: Int
    let name: String
    var purchaseNetValue: Double
    var investmentsNetValue: Double
    var isUnderConstruction: Bool
    var constructionFinishMonth: Int
    
    init(_ road: Road) {
        self.uuid = UUID().uuidString
        self.ownerUUID = road.ownerUUID
        self.x = road.address.x
        self.y = road.address.y
        self.name = road.name
        self.purchaseNetValue = road.purchaseNetValue
        self.investmentsNetValue = road.investmentsNetValue
        self.isUnderConstruction = road.isUnderConstruction
        self.constructionFinishMonth = road.constructionFinishMonth
    }
}
