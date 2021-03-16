//
//  GameEngine.swift
//  
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation
import RxSwift
import RxCocoa

class GameEngine {
    let gameMap: GameMap
    let gameTraffic: GameTraffic
    let websocketHandler: WebsocketHandler
    let gameEvents = PublishSubject<GameEvent>()
    let disposeBag = DisposeBag()
    private var playerSessions: [PlayerSession]
    
    init() {
        self.gameMap = GameMap(width: 25, height: 25, scale: 0.20, path: "maps/roadMap1")
        self.gameTraffic = GameTraffic(gameMap: self.gameMap)
        self.websocketHandler = WebsocketHandler()
        self.playerSessions = []
        
        self.websocketHandler.events.asObservable().bind { websocketEvent in
            guard let player = (self.playerSessions.first { $0.id == websocketEvent.playerSesssionID }?.player) else {
                Logger.error("GameEngine", "websocketEvent has no player assosiated")
                return
            }
            switch websocketEvent.eventType {
                
            case .tileClicked(let mapPoint):
                Logger.info("GameEngine", "\(player.login) clicked \(mapPoint)")
                let gameEvent = GameEvent(player: player, action: .tileClicked(mapPoint))
                self.gameEvents.onNext(gameEvent)
            case .userConnected:
                Logger.info("GameEngine", "\(player.login) connected")
                let gameEvent = GameEvent(player: player, action: .userConnected)
                self.gameEvents.onNext(gameEvent)
            case .userDisconnected:
                Logger.info("GameEngine", "\(player.login) disconnected")
                let gameEvent = GameEvent(player: player, action: .userDisconnected)
                self.gameEvents.onNext(gameEvent)
            }
        }.disposed(by: self.disposeBag)
        
        self.gameTraffic.events.asObservable().bind { [weak self] trafficEvent in
            switch trafficEvent {
                
            case .vehicleTravel(let payload):
                self?.websocketHandler.sendToAll(commandType: .startVehicle, payload: payload)
            }
        }.disposed(by: self.disposeBag)
        
        self.gameEvents.asObservable().bind { [weak self] gameEvent in
            switch gameEvent.action {
            case .reloadMap:
                self?.websocketHandler.sendToAll(commandType: .reloadMap, payload: "\(gameEvent.player?.id ?? "nil")")
            case .tileClicked(let point):

                let tile = GameMapTile(address: point, type: .building)
                self?.gameMap.replaceTile(tile: tile)
                let gameEvent = GameEvent(player: gameEvent.player, action: .reloadMap)
                self?.gameEvents.onNext(gameEvent)
            default:
                break
            }
        }.disposed(by: self.disposeBag)
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
