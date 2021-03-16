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
    private var playerSessions: [PlayerSession]
    
    init() {
        self.gameMap = GameMap(width: 25, height: 25, scale: 0.40, path: "maps/roadMap1")
        self.gameTraffic = GameTraffic(gameMap: self.gameMap)
        self.websocketHandler = WebsocketHandler()
        self.playerSessions = []
        
        self.websocketHandler.events.asObservable().bind { websocketEvent in
            
        }.disposed(by: self.disposeBag)
        
        self.gameTraffic.events.asObservable().bind { [weak self] trafficEvent in
            switch trafficEvent {
                
            case .vehicleTravel(let payload):
                self?.websocketHandler.sendToAll(commandType: .startVehicle, payload: payload)
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
