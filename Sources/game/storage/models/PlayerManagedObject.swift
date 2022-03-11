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
    var wallet: Double

    init(_ player: Player) {
        self.uuid = player.uuid.isEmpty ? UUID().uuidString : player.uuid
        self.login = player.login
        self.wallet = player.wallet
    }
}
