//
//  WebsocketHandler.swift
//  
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation
import Swifter

class WebsocketHandler {
    
    private var sessions: [WebSocketSession] = []
    
    func add(session: WebSocketSession) {
        self.sessions.append(session)
    }
    
    func remove(session: WebSocketSession) {
        self.sessions.remove(object: session)
    }
    
    func sendToAll<T:Codable>(commandType: WebsocketCommandOutType, payload: T) {
        let command = WebsocketOutCommand<T>(payload)
        if let json = command.toJSONString() {
            self.sessions.forEach { session in
                session.writeText(json)
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
            }
        }
    }
}
