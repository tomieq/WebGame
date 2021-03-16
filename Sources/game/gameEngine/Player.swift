//
//  Player.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

struct Player {
    let id: String
    let login: String
}

class PlayerSession {
    let id: String
    let player: Player
    
    init(player: Player) {
        self.id = UUID().uuidString
        self.player = player
    }
}
