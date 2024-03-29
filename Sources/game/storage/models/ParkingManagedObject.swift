//
//  ParkingManagedObject.swift
//
//
//  Created by Tomasz Kucharski on 04/11/2021.
//

import Foundation

class ParkingManagedObject: Codable {
    let uuid: String
    var ownerUUID: String
    let x: Int
    let y: Int
    let name: String
    var purchaseNetValue: Double
    var investmentsNetValue: Double
    var isUnderConstruction: Bool
    var constructionFinishMonth: Int
    var insurance: String
    var security: String
    var advertising: String
    var trustLevel: Double

    init(_ parking: Parking) {
        self.uuid = parking.uuid.isEmpty ? UUID().uuidString : parking.uuid
        self.ownerUUID = parking.ownerUUID
        self.x = parking.address.x
        self.y = parking.address.y
        self.name = parking.name
        self.purchaseNetValue = parking.purchaseNetValue
        self.investmentsNetValue = parking.investmentsNetValue
        self.isUnderConstruction = parking.isUnderConstruction
        self.constructionFinishMonth = parking.constructionFinishMonth
        self.insurance = parking.insurance.rawValue
        self.security = parking.security.rawValue
        self.advertising = parking.advertising.rawValue
        self.trustLevel = parking.trustLevel
    }
}
