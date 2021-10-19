//
//  Player.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

enum SystemPlayer: String, CaseIterable {
    case government
    case bank
    case realEstateAgency
    
    var uuid: String {
        return self.rawValue
    }
}

struct Player: Codable {
    let uuid: String
    let login: String
    let wallet: Double
    
    init(uuid: String? = nil, login: String, wallet: Double) {
        self.uuid = uuid ?? ""
        self.login = login
        self.wallet = wallet
    }
    
    init(_ managedObject: PlayerManagedObject) {
        self.uuid = managedObject.uuid
        self.login = managedObject.login
        self.wallet = managedObject.wallet
    }
    
    var isSystemPlayer: Bool {
        return SystemPlayer.allCases.map{ $0.uuid }.contains(self.uuid)
    }
}

struct PlayerMutation {
    let id: String
    let attributes: [PlayerMutation.Attribute]
    
    enum Attribute {
        case wallet(Double)
    }
}
