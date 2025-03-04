//
//  PropertyRegister.swift
//
//
//  Created by Tomasz Kucharski on 02/11/2021.
//

import Foundation

enum PropertyType: String, Codable {
    case land
    case road
    case parking
    case residentialBuilding
    case apartment
}

enum PropertyStatus: String {
    case normal
    case blockedByDebtCollector
}

struct PropertyRegister {
    let uuid: String
    let address: MapPoint
    let ownerUUID: String
    let type: PropertyType
    let status: PropertyStatus

    init(uuid: String, address: MapPoint, playerUUID: String, type: PropertyType) {
        self.uuid = uuid
        self.address = address
        self.ownerUUID = playerUUID
        self.type = type
        self.status = .normal
    }

    init(_ managedObject: PropertyRegisterManagedObject) {
        self.uuid = managedObject.uuid
        self.address = managedObject.address
        self.ownerUUID = managedObject.ownerUUID
        self.type = managedObject.type
        self.status = managedObject.status
    }
}

extension PropertyRegister: Equatable {
    static func == (lhs: PropertyRegister, rhs: PropertyRegister) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

struct PropertyRegisterMutation {
    let uuid: String
    let attributes: [PropertyRegisterMutation.Attribute]

    enum Attribute {
        case ownerUUID(String)
        case type(PropertyType)
        case status(PropertyStatus)
    }
}
