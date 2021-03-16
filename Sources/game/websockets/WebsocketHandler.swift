//
//  WebsocketHandler.swift
//  
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation
import Swifter

class WebsocketHandler {
    
    private var playerSessions: [PlayerWebsocketSession] = []
    
    func add(session: WebSocketSession) {
        self.playerSessions.append(PlayerWebsocketSession(websocketSession: session))
    }
    
    func remove(session: WebSocketSession) {
        self.playerSessions = self.playerSessions.filter { $0.websocketSession != session }
    }
    
    
    func sendTo<T:Codable>(playerSessionID: String, commandType: WebsocketCommandOutType, payload: T) {
        let command = WebsocketOutCommand<T>(payload)
        if let json = command.toJSONString() {
            self.playerSessions.filter{ $0.playerSessionID == playerSessionID}.forEach { playerSession in
                playerSession.websocketSession.writeText(json)
            }
        } else {
            Logger.error("WebsocketHandler", "Couldn't serialize command \(commandType)")
        }
        
    }
    
    func sendToAll<T:Codable>(commandType: WebsocketCommandOutType, payload: T) {
        let command = WebsocketOutCommand<T>(payload)
        if let json = command.toJSONString() {
            self.playerSessions.forEach { playerSession in
                playerSession.websocketSession.writeText(json)
            }
        } else {
            Logger.error("WebsocketHandler", "Couldn't serialize command \(commandType)")
        }
        
    }
    
    func handle(session: WebSocketSession, text: String) {
        if let data = text.data(using: .utf8),
            let dto = try? JSONDecoder().decode(WebsocketInCommand.self, from: data),
            let command = dto.command {
            
            Logger.info("DBG", "Incomming websocket command \(command)")
            switch command {
            case .tileClicked:
                if let dto = try? JSONDecoder().decode(WebsocketInCommandWithPayload<MapPoint>.self, from: data),
                    let point = dto.payload {
                    Logger.info("WebsocketHandler", "Tile clicked \(point)")
                }
            case .playerSessionID:
                if let dto = try? JSONDecoder().decode(WebsocketInCommandWithPayload<String>.self, from: data),
                    let playerSessionID = dto.payload {
                    self.playerSessions.first{ $0.websocketSession == session }?.playerSessionID = playerSessionID
                     Logger.info("WebsocketHandler", "Websocket registered for \(playerSessionID)")
                 }
            }
        }
    }
}
