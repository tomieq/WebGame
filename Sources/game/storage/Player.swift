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
    let wallet: Double
    
    init(_ managedObject: PlayerManagedObject) {
        self.id = managedObject.id
        self.login = managedObject.login
        self.type = managedObject.type
        self.wallet = managedObject.wallet
    }
    
    func pay(_ amount: Double) {
        let value = (self.wallet - amount).rounded(toPlaces: 0)
        DataStore.provider.update(PlayerMutation(id: self.id, attributes: [.wallet(value)]))
    }
    
    func receiveMoney(_ amount: Double) {
        let value = (self.wallet + amount).rounded(toPlaces: 0)
        DataStore.provider.update(PlayerMutation(id: self.id, attributes: [.wallet(value)]))
    }
    
    enum Attribute {
        case wallet(Double)
    }
}

struct PlayerMutation {
    let id: String
    let attributes: [Player.Attribute]
}
