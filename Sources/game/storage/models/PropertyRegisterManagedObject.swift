//
//  PropertyRegisterManagedObject.swift
//  
//
//  Created by Tomasz Kucharski on 02/11/2021.
//

import Foundation

class PropertyRegisterManagedObject {
    let uuid: String
    let address: MapPoint
    var ownerUUID: String
    var type: PropertyType
    var status: PropertyStatus
    
    init(_ register: PropertyRegister) {
        self.uuid = register.uuid
        self.address = register.address
        self.ownerUUID = register.ownerUUID
        self.type = register.type
        self.status = register.status
    }
}
