//
//  PlayerSessionManager.swift
//
//
//  Created by Tomasz Kucharski on 17/03/2021.
//

import Foundation

class PlayerSessionManager {
    static let shared = PlayerSessionManager()

    private var playerSessions: [PlayerSession]

    private init() {
        self.playerSessions = []
    }

    func getActiveSessions() -> [PlayerSession] {
        return self.playerSessions
    }

    func createPlayerSession(for player: Player) -> PlayerSession {
        let playerSession = PlayerSession(player: player)
        self.playerSessions.append(playerSession)
        return playerSession
    }

    func destroyPlayerSession(playerSessionID: String) {
        self.playerSessions = self.playerSessions.filter{ $0.id != playerSessionID }
    }

    func getPlayerSession(playerSessionID: String) -> PlayerSession? {
        return self.playerSessions.first{ $0.id == playerSessionID }
    }

    func getSessions(playerUUID: String) -> [PlayerSession] {
        return self.playerSessions.filter{ $0.playerUUID == playerUUID }
    }
}
