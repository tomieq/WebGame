//
//  PropertyRegisterManagedObject.swift
//  
//
//  Created by Tomasz Kucharski on 02/11/2021.
//

import Foundation

class PropertyRegisterManagedObject {
    let uuid: String
    var playerUUID: String
    let propertyUUID: String
    var type: PropertyType
    
    init(_ register: PropertyRegister) {
        self.uuid = UUID().uuidString
        self.playerUUID = register.playerUUID
        self.propertyUUID = register.propertyUUID
        self.type = register.type
    }
}
