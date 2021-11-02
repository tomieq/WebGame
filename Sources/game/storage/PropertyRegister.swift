//
//  PropertyRegister.swift
//  
//
//  Created by Tomasz Kucharski on 02/11/2021.
//

import Foundation

enum PropertyType: String {
    case land
    case road
    case residentialBuilding
}

enum PropertyStatus: String {
    case normal
    case blockedByDebtCollector
}

struct PropertyRegister {
    let uuid: String
    let ownerUUID: String
    let type: PropertyType
    let status: PropertyStatus

    init(uuid: String, playerUUID: String, type: PropertyType) {
        self.uuid = uuid
        self.ownerUUID = playerUUID
        self.type = type
        self.status = .normal
    }

    init(_ managedObject: PropertyRegisterManagedObject) {
        self.uuid = managedObject.uuid
        self.ownerUUID = managedObject.ownerUUID
        self.type = managedObject.type
        self.status = managedObject.status
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
