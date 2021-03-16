//
//  GameEngine.swift
//  
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation

class GameEngine {
    let gameMap: GameMap
    let gameTraffic: GameTraffic
    let websocketHandler: WebsocketHandler
    private var playerSessions: [PlayerSession]
    
    init() {
        self.gameMap = GameMap(width: 25, height: 25, scale: 0.40, path: "maps/roadMap1")
        self.gameTraffic = GameTraffic(gameMap: self.gameMap)
        self.websocketHandler = WebsocketHandler()
        self.playerSessions = []
    }
    
    func makePlayerSession(player: Player) -> PlayerSession {
        let playerSession = PlayerSession(player: player)
        self.playerSessions.append(playerSession)
        return playerSession
    }
    
    func getPlayerSession(id: String) -> PlayerSession? {
        return self.playerSessions.first{ $0.id == id }
    }
}
