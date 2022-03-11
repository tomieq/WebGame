//
//  PlayerSession.swift
//
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

class PlayerSession {
    let id: String
    let playerUUID: String

    init(player: Player) {
        self.id = UUID().uuidString
        self.playerUUID = player.uuid
    }
}

extension PlayerSession: Equatable {
    static func == (lhs: PlayerSession, rhs: PlayerSession) -> Bool {
        lhs.id == rhs.id
    }
}

extension PlayerSession: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
