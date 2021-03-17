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
    let realEstateAgent: RealEstateAgent
    let disposeBag = DisposeBag()
    
    init() {
        self.gameMap = GameMap(width: 25, height: 25, scale: 0.30, path: "maps/roadMap1")
        self.gameTraffic = GameTraffic(gameMap: self.gameMap)
        self.websocketHandler = WebsocketHandler()
        self.realEstateAgent = RealEstateAgent(map: self.gameMap)

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
                if self?.gameMap.getTile(address: point) == nil {
                    let land = Land(address: point)
                    self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .alert, payload: "The value is \(self?.realEstateAgent.evaluatePrice(land) ?? 0)")
                }
                
                var sizes = [4,6,8,10]
                sizes.shuffle()
                let tile = GameMapTile(address: point, type: .building(size: sizes.first!))
                self?.realEstateAgent.putTile(tile)
                self?.websocketHandler.sendToAll(commandType: .reloadMap, payload: "\(gameEvent.playerSession?.player.id ?? "nil")")
                break
            case .vehicleTravelStarted(let payload):
                switch gameEvent.playerSession {
                case .none:
                    self?.websocketHandler.sendToAll(commandType: .startVehicle, payload: payload)
                case .some(let playerSession):
                    self?.websocketHandler.sendTo(playerSessionID: playerSession.id, commandType: .startVehicle, payload: payload)
                }
            default:
                break
            }
        }.disposed(by: self.disposeBag)
    }
}


