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
    let disposeBag = DisposeBag()
    
    init() {
        self.gameMap = GameMap(width: 25, height: 25, scale: 0.20, path: "maps/roadMap1")
        self.gameTraffic = GameTraffic(gameMap: self.gameMap)
        self.websocketHandler = WebsocketHandler()
        
        self.gameTraffic.events.asObservable().bind { [weak self] trafficEvent in
            switch trafficEvent {
                
            case .vehicleTravel(let payload):
                self?.websocketHandler.sendToAll(commandType: .startVehicle, payload: payload)
            }
        }.disposed(by: self.disposeBag)
        
        GameEventBus.gameEvents.asObservable().bind { [weak self] gameEvent in
            switch gameEvent.action {
            case .reloadMap:
                self?.websocketHandler.sendToAll(commandType: .reloadMap, payload: "\(gameEvent.playerSession?.player.id ?? "nil")")
            case .tileClicked(let point):

                
                if let points = self?.gameMap.getNeighbourAddresses(to: point, radius: 1) {
                    let payload = HighlightArea(points: points, color: "red")
                    self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .highlightArea, payload: payload)
                }
                if let points = self?.gameMap.getNeighbourAddresses(to: point, radius: 2) {
                    let payload = HighlightArea(points: points, color: "red")
                    self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .highlightArea, payload: payload)
                }
                if let points = self?.gameMap.getNeighbourAddresses(to: point, radius: 3) {
                    let payload = HighlightArea(points: points, color: "orange")
                    self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .highlightArea, payload: payload)
                }
                /*if self?.gameMap.getTile(address: point) == nil {
                    let land = Land(address: point, map: self!.gameMap)
                    self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .alert, payload: "The value is \(land.moneyValue)")
                }*/
                /*let tile = GameMapTile(address: point, type: .building)
                self?.gameMap.replaceTile(tile: tile)
                let gameEvent = GameEvent(player: gameEvent.player, action: .reloadMap)
                self?.gameEvents.onNext(gameEvent)*/
                break
            default:
                break
            }
        }.disposed(by: self.disposeBag)
    }
}


