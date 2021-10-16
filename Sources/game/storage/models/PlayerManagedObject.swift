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
    
    init(_ player: Player) {
        self.uuid = UUID().uuidString
        self.login = player.login
        self.type = player.type
        self.wallet = player.wallet
    }
}
