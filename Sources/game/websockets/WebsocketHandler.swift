//
//  WebsocketHandler.swift
//  
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation
import Swifter
import RxSwift

class WebsocketHandler {
    
    let events = PublishSubject<WebsocketEvent>()
    private var playerSessions: [PlayerWebsocketSession] = []
    
    func add(websocketSession: WebSocketSession) {
        self.playerSessions.append(PlayerWebsocketSession(websocketSession: websocketSession))
    }
    
    func remove(websocketSession: WebSocketSession) {
        self.playerSessions = self.playerSessions.filter { $0.websocketSession != websocketSession }
    }
    
    
    func sendTo<T:Codable>(playerSessionID: String, commandType: WebsocketCommandOutType, payload: T) {
        let command = WebsocketOutCommand<T>(commandType, payload)
        if let json = command.toJSONString() {
            self.playerSessions.filter{ $0.playerSessionID == playerSessionID}.forEach { playerSession in
                playerSession.websocketSession.writeText(json)
            }
        } else {
            Logger.error("WebsocketHandler", "Couldn't serialize command \(commandType)")
        }
        
    }
    
    func sendToAll<T:Codable>(commandType: WebsocketCommandOutType, payload: T) {
        let command = WebsocketOutCommand<T>(commandType, payload)
        if let json = command.toJSONString() {
            Logger.info("WebsocketHandler", "Send to all: \(json)")
            self.playerSessions.forEach { playerSession in
                playerSession.websocketSession.writeText(json)
            }
        } else {
            Logger.error("WebsocketHandler", "Couldn't serialize command \(commandType)")
        }
        
    }
    
    func handleMessage(websocketSession: WebSocketSession, text: String) {
        
        if let data = text.data(using: .utf8),
            let dto = try? JSONDecoder().decode(WebsocketInCommand.self, from: data),
            let command = dto.command {

            switch command {
            case .playerSessionID:
                if let dto = try? JSONDecoder().decode(WebsocketInCommandWithPayload<String>.self, from: data),
                    let playerSessionID = dto.payload {
                    self.playerSessions.first{ $0.websocketSession == websocketSession }?.playerSessionID = playerSessionID
                     Logger.info("WebsocketHandler", "Websocket registered for \(playerSessionID)")
                 }
            
            case .tileClicked:
                guard let playerSessionID = self.getPlayerSessionID(websocketSession) else { return }
                if let dto = try? JSONDecoder().decode(WebsocketInCommandWithPayload<MapPoint>.self, from: data),
                    let point = dto.payload {
                    Logger.info("WebsocketHandler", "Tile clicked \(point)")
                    self.events.onNext(WebsocketEvent(playerSesssionID: playerSessionID, eventType: .tileClicked(point)))
                }
            }
        }
    }
    
    private func getPlayerSessionID(_ websocketSession: WebSocketSession) -> String? {
        if let playerSessionID = (self.playerSessions.first{ $0.websocketSession == websocketSession }) {
            return playerSessionID.playerSessionID
        }
        Logger.error("WebsocketHandler", "WebSocketSession is not connected to PlayerSession")
        websocketSession.writeCloseFrame()
        return nil
    }
}
