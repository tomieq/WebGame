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
    
    private var activeSessions: [PlayerWebsocketSession] = []
    
    func add(websocketSession: WebSocketSession) {
        self.activeSessions.append(PlayerWebsocketSession(websocketSession: websocketSession))
    }
    
    func remove(websocketSession: WebSocketSession) {
        if let playerSession = self.getPlayerSession(websocketSession) {
            let event = GameEvent(playerSession: playerSession, action: .userDisconnected)
            GameEventBus.gameEvents.onNext(event)
        }
        self.activeSessions = self.activeSessions.filter { $0.websocketSession != websocketSession }
    }
    
    
    func sendTo(playerSessionID: String?, command: WebsocketOutCommand) {
        let json = command.json
        Logger.info("WebsocketHandler", "Send to \(playerSessionID ?? "nil"): \(json)")
        for playerSession in (self.activeSessions.filter{ $0.playerSession?.id == playerSessionID}) {
            playerSession.websocketSession.writeText(json)
        }
    }
    
    func sendToAll(command: WebsocketOutCommand) {
        let json = command.json
        Logger.info("WebsocketHandler", "Send to all: \(json)")
        for playerSession in self.activeSessions {
            playerSession.websocketSession.writeText(json)
        }
    }
    
    func sendToAll(command: WebsocketOutCommand, exceptUserUUIDs: [String]) {
        let json = command.json
        Logger.info("WebsocketHandler", "Send to all: \(json) excluding \(exceptUserUUIDs.count) users")
        for playerSession in self.activeSessions {
            if let playerUUID = playerSession.playerSession?.playerUUID, !exceptUserUUIDs.contains(playerUUID) {
                playerSession.websocketSession.writeText(json)
            }
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
                    guard let gobalSession = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                        let info = "Cannot establish websocket session. Couldn't find related web session"
                        Logger.error("WebsocketHandler", info)
                        websocketSession.writeText(info)
                        websocketSession.writeCloseFrame()
                        return
                    }
                    self.activeSessions.first{ $0.websocketSession == websocketSession }?.playerSession = gobalSession
                    Logger.info("WebsocketHandler", "Websocket registered for \(playerSessionID)")
                    let event = GameEvent(playerSession: gobalSession, action: .userConnected)
                    GameEventBus.gameEvents.onNext(event)
                 }
            
            case .tileClicked:
                guard let playerSession = self.getPlayerSession(websocketSession) else { return }
                if let dto = try? JSONDecoder().decode(WebsocketInCommandWithPayload<MapPoint>.self, from: data),
                    let point = dto.payload {
                    let event = GameEvent(playerSession: playerSession, action: .tileClicked(point))
                    GameEventBus.gameEvents.onNext(event)
                }
            case .vehicleFinished:
                guard let playerSession = self.getPlayerSession(websocketSession) else { return }
                if let dto = try? JSONDecoder().decode(WebsocketInCommandWithPayload<VehicleTravelFinished>.self, from: data),
                    let payload = dto.payload {
                    let event = GameEvent(playerSession: playerSession, action: .vehicleTravelFinished(payload))
                    GameEventBus.gameEvents.onNext(event)
                }
            }
        }
    }
    
    private func getPlayerSession(_ websocketSession: WebSocketSession) -> PlayerSession? {
        if let activeSession = (self.activeSessions.first{ $0.websocketSession == websocketSession }) {
            return activeSession.playerSession
        }
        let info = "WebSocketSession is not connected to PlayerSession. Closing"
        Logger.error("WebsocketHandler", info)
        websocketSession.writeText(info)
        websocketSession.writeCloseFrame()
        return nil
    }
}
