//
//  Player.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

enum PlayerType: String, Codable {
    case user
    case government
    case bank
    case realEstateAgency
}

struct Player: Codable {
    let id: String
    let login: String
    let type: PlayerType
    var wallet: Double
    
    init(_ managedObject: PlayerManagedObject) {
        self.id = managedObject.id
        self.login = managedObject.login
        self.type = managedObject.type
        self.wallet = managedObject.wallet
    }
    
    func pay(_ amount: Double) {
        //self.wallet -= amount.rounded(toPlaces: 0)
    }
    
    func receiveMoney(_ amount: Double) {
        //self.wallet += amount.rounded(toPlaces: 0)
    }
    
    enum Attribute {
        case wallet(Double)
    }
}

struct PlayerMutation {
    let id: String
    let attributes: [Player.Attribute]
}
