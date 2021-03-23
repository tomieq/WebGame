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
            case .userConnected:
                if let session = gameEvent.playerSession {
                    self?.websocketHandler.sendTo(playerSessionID: session.id, commandType: .updateWallet, payload: session.player.wallet.money)
                }
            case .reloadMap:
                self?.websocketHandler.sendToAll(commandType: .reloadMap, payload: "\(gameEvent.playerSession?.player.id ?? "nil")")
            case .updateWallet(let wallet):
                self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .updateWallet, payload: wallet)
            case .tileClicked(let point):

                switch self?.realEstateAgent.isForSale(address: point) ?? false {
                    case true:
                        let payload = OpenWindow(title: "Sale offer", width: 300, height: 300, initUrl: "/openSaleOffer.js?x=\(point.x)&y=\(point.y)", address: point)
                        self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .openWindow, payload: payload)
                    case false:
                        
                        let payload = OpenWindow(title: "Property info", width: 300, height: 200, initUrl: "/openPropertyInfo.js?x=\(point.x)&y=\(point.y)", address: point)
                        self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .openWindow, payload: payload)
                        break
                }
                
                /*
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
 */


                break
            case .vehicleTravelStarted(let payload):
                switch gameEvent.playerSession {
                case .none:
                    self?.websocketHandler.sendToAll(commandType: .startVehicle, payload: payload)
                case .some(let playerSession):
                    self?.websocketHandler.sendTo(playerSessionID: playerSession.id, commandType: .startVehicle, payload: payload)
                }
            case .notification(let payload):
                switch gameEvent.playerSession {
                case .none:
                    self?.websocketHandler.sendToAll(commandType: .notification, payload: payload)
                case .some(let playerSession):
                    self?.websocketHandler.sendTo(playerSessionID: playerSession.id, commandType: .notification, payload: payload)
                }
            default:
                break
            }
        }.disposed(by: self.disposeBag)
    }
}


