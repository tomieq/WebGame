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

struct PropertyRegister {
    let uuid: String
    let ownerUUID: String
    let type: PropertyType

    init(uuid: String, playerUUID: String, type: PropertyType) {
        self.uuid = uuid
        self.ownerUUID = playerUUID
        self.type = type
    }

    init(_ managedObject: PropertyRegisterManagedObject) {
        self.uuid = managedObject.uuid
        self.ownerUUID = managedObject.ownerUUID
        self.type = managedObject.type
    }
}

struct PropertyRegisterMutation {
    let uuid: String
    let attributes: [PropertyRegisterMutation.Attribute]
    
    enum Attribute {
        case playerUUID(String)
        case type(PropertyType)
    }
}
