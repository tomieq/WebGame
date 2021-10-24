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
    let time: GameTime
    let dataStore: DataStoreProvider
    let taxRates: TaxRates
    let centralbank: CentralBank
    let gameMap: GameMap
    let gameMapManager: GameMapManager
    let streetNavi: StreetNavi
    let gameTraffic: GameTraffic
    let websocketHandler: WebsocketHandler
    let propertyValuer: PropertyValuer
    let realEstateAgent: RealEstateAgent
    let constructionServices: ConstructionServices
    let gameClock: GameClock
    let clickRouter: ClickTileRouter
    let disposeBag = DisposeBag()
    
    init(dataStore: DataStoreProvider) {
        self.time = GameTime()
        self.dataStore = dataStore
        self.taxRates = TaxRates()
        self.centralbank = CentralBank(dataStore: self.dataStore, taxRates: self.taxRates, time: self.time)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: SystemPlayer.government.login, wallet: 0)
        let realEstateAgent = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: SystemPlayer.realEstateAgency.login, wallet: 0)
        let user1 = Player(uuid: "p1", login: "Mike Wachlewsky", wallet: 10000000)
        let user2 = Player(uuid: "p2", login: "Richard Smith", wallet: 10000000)
        self.dataStore.create(government)
        self.dataStore.create(realEstateAgent)
        self.dataStore.create(user1)
        self.dataStore.create(user2)
        
        self.gameMap = GameMap(width: 25, height: 25, scale: 0.30)
        self.gameMapManager = GameMapManager(self.gameMap)
        self.gameMapManager.loadMapFrom(path: "maps/roadMap1")
        
        MapStorageSync(mapManager: self.gameMapManager, dataStore: self.dataStore).syncMapWithDataStore()
        
        self.propertyValuer = PropertyValuer(mapManager: self.gameMapManager, dataStore: self.dataStore)
        self.realEstateAgent = RealEstateAgent(mapManager: self.gameMapManager, propertyValuer: self.propertyValuer, centralBank: self.centralbank)
        
        self.constructionServices = ConstructionServices(mapManager: self.gameMapManager, centralBank: self.centralbank, time: self.time)
        
        self.streetNavi = StreetNavi(gameMap: self.gameMap)
        self.gameTraffic = GameTraffic(streetNavi: self.streetNavi)
        self.websocketHandler = WebsocketHandler()
        self.gameClock = GameClock(realEstateAgent: self.realEstateAgent, time: self.time, secondsPerMonth: 60*10)
        
        self.clickRouter = ClickTileRouter(agent: self.realEstateAgent)
        
        self.realEstateAgent.delegate = self
        self.constructionServices.delegate = self
        
        self.setupDevParams()

        GameEventBus.gameEvents.asObservable().bind { [weak self] gameEvent in
            switch gameEvent.action {
            case .userConnected:
                if let session = gameEvent.playerSession, let player = self?.dataStore.find(uuid: session.playerUUID) {
                    self?.websocketHandler.sendTo(playerSessionID: session.id, command: .updateWallet(player.wallet.money))
                    if let text = self?.gameClock.time.text, let secondsLeft = self?.gameClock.secondsLeft {
                        self?.websocketHandler.sendToAll(command: .updateGameDate(UIGameDate(text: text, secondsLeft: secondsLeft)))
                    }
                }
            case .userDisconnected:
                if let session = gameEvent.playerSession {
                    PlayerSessionManager.shared.destroyPlayerSession(playerSessionID: session.id)
                }
            case .reloadMap:
                self?.streetNavi.reload()
                self?.websocketHandler.sendToAll(command: .reloadMap)
            case .updateWallet(let wallet):
                self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, command: .updateWallet(wallet))
            case .updateGameDate(let date, let secondsLeft):
                self?.constructionServices.finishInvestments()
                self?.websocketHandler.sendToAll(command: .updateGameDate(UIGameDate(text: date, secondsLeft: secondsLeft)))
            case .tileClicked(let point):

                let playerUUID = gameEvent.playerSession?.playerUUID
                
                
                if let commands = self?.clickRouter.action(address: point, playerUUID: playerUUID).commands(point: point) {
                    for command in commands {
                        self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, command: command)
                    }
                }
                
                /*
                if let points = self?.gameMap.getNeighbourAddresses(to: point, radius: 1) {
                    let payload = HighlightArea(points: points, color: "red")
                    self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, command: .highlightArea(payload))
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
                    self?.websocketHandler.sendToAll(command: .startVehicle(payload))
                case .some(let playerSession):
                    self?.websocketHandler.sendTo(playerSessionID: playerSession.id, command: .startVehicle(payload))
                }
            case .notification(let payload):
                switch gameEvent.playerSession {
                case .none:
                    self?.websocketHandler.sendToAll(command: .notification(payload))
                case .some(let playerSession):
                    self?.websocketHandler.sendTo(playerSessionID: playerSession.id, command: .notification(payload))
                }
            default:
                break
            }
        }.disposed(by: self.disposeBag)
    }
    
    private func setupDevParams() {
        self.constructionServices.constructionDuration.road = 1
        self.constructionServices.constructionDuration.residentialBuilding = 1
        self.constructionServices.constructionDuration.residentialBuildingPerStorey = 0
    }
}


extension GameEngine: RealEstateAgentDelegate, ConstructionServicesDelegate {
    func notifyWalletChange(playerUUID: String) {
        if let player = self.dataStore.find(uuid: playerUUID) {
            for session in PlayerSessionManager.shared.getSessions(playerUUID: playerUUID){
                let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(player.wallet.money))
                GameEventBus.gameEvents.onNext(updateWalletEvent)
            }
        }
    }
    func reloadMap() {
        let reloadMapEvent = GameEvent(playerSession: nil, action: .reloadMap)
        GameEventBus.gameEvents.onNext(reloadMapEvent)
    }
    
    func notifyEveryone(_ notification: UINotification) {
        let announcementEvent = GameEvent(playerSession: nil, action: .notification(notification))
                GameEventBus.gameEvents.onNext(announcementEvent)
    }
}
