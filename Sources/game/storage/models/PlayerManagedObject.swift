//
//  PlayerManagedObject.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

class PlayerManagedObject {
    let uuid: String
    let login: String
    let type: PlayerType
    var wallet: Double
    
    init(_ player: PlayerCreateRequest) {
        self.uuid = UUID().uuidString
        self.login = player.login
        self.type = player.type
        self.wallet = player.wallet
    }
}

struct PlayerCreateRequest {
    let login: String
    let type: PlayerType
    var wallet: Double
    
    init(login: String, type: PlayerType = .user, wallet: Double) {
        self.login = login
        self.type = type
        self.wallet = wallet
    }
}

struct PlayerMutationRequest {
    let id: String
    let attributes: [PlayerMutationRequest.Attribute]
    
    enum Attribute {
        case wallet(Double)
    }
}
