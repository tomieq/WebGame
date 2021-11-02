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
    let playerUUID: String
    let propertyUUID: String
    let type: PropertyType

    init(_ managedObject: PropertyRegisterManagedObject) {
        self.uuid = managedObject.uuid
        self.playerUUID = managedObject.playerUUID
        self.propertyUUID = managedObject.propertyUUID
        self.type = managedObject.type
    }
}
