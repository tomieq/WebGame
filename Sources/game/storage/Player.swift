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
    let uuid: String
    let login: String
    let type: PlayerType
    let wallet: Double
    
    init(_ managedObject: PlayerManagedObject) {
        self.uuid = managedObject.uuid
        self.login = managedObject.login
        self.type = managedObject.type
        self.wallet = managedObject.wallet
    }
    
    func pay(_ amount: Double) {
        let value = (self.wallet - amount).rounded(toPlaces: 0)
        DataStore.provider.update(PlayerMutationRequest(id: self.uuid, attributes: [.wallet(value)]))
    }
    
    func receiveMoney(_ amount: Double) {
        let value = (self.wallet + amount).rounded(toPlaces: 0)
        DataStore.provider.update(PlayerMutationRequest(id: self.uuid, attributes: [.wallet(value)]))
    }
    

}
