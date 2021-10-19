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
    let realEstateAgent: RealEstateAgent
    let constructionServices: ConstructionServices
    let gameClock: GameClock
    let disposeBag = DisposeBag()
    
    init(dataStore: DataStoreProvider) {
        self.time = GameTime()
        self.time.month = Storage.shared.monthIteration
        self.dataStore = dataStore
        self.taxRates = TaxRates()
        self.centralbank = CentralBank(dataStore: self.dataStore, taxRates: self.taxRates)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Government", wallet: 0)
        let realEstateAgent = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: "Real Estate Agency", wallet: 0)
        let user1 = Player(uuid: "p1", login: "Mike Wachlewsky", wallet: 2000000)
        self.dataStore.create(government)
        self.dataStore.create(realEstateAgent)
        self.dataStore.create(user1)
        
        self.gameMap = GameMap(width: 25, height: 25, scale: 0.30)
        self.gameMapManager = GameMapManager(self.gameMap)
        self.gameMapManager.loadMapFrom(path: "maps/roadMap1")
        
        self.realEstateAgent = RealEstateAgent(mapManager: self.gameMapManager, centralBank: self.centralbank)
        self.realEstateAgent.makeMapTilesFromDataStore()
        
        self.constructionServices = ConstructionServices(mapManager: self.gameMapManager, centralBank: self.centralbank, time: self.time)
        
        self.streetNavi = StreetNavi(gameMap: self.gameMap)
        self.gameTraffic = GameTraffic(streetNavi: self.streetNavi)
        self.websocketHandler = WebsocketHandler()
        self.gameClock = GameClock(realEstateAgent: self.realEstateAgent, time: self.time)
        
        self.realEstateAgent.delegate = self
        self.constructionServices.delegate = self

        GameEventBus.gameEvents.asObservable().bind { [weak self] gameEvent in
            switch gameEvent.action {
            case .userConnected:
                if let session = gameEvent.playerSession, let player = self?.dataStore.find(uuid: session.playerUUID) {
                    self?.websocketHandler.sendTo(playerSessionID: session.id, commandType: .updateWallet, payload: player.wallet.money)
                }
            case .userDisconnected:
                if let session = gameEvent.playerSession {
                    PlayerSessionManager.shared.destroyPlayerSession(playerSessionID: session.id)
                }
            case .reloadMap:
                self?.streetNavi.reload()
                self?.websocketHandler.sendToAll(commandType: .reloadMap, payload: "\(gameEvent.playerSession?.playerUUID ?? "nil")")
            case .updateWallet(let wallet):
                self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .updateWallet, payload: wallet)
            case .updateGameDate(let date):
                self?.constructionServices.finishInvestments()
                self?.websocketHandler.sendToAll(commandType: .updateGameDate, payload: date)
            case .tileClicked(let point):

                switch self?.realEstateAgent.isForSale(address: point) ?? false {
                    case true:
                        let payload = OpenWindow(title: "Sale offer", width: 300, height: 250, initUrl: "/openSaleOffer.js?x=\(point.x)&y=\(point.y)", address: point)
                        self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .openWindow, payload: payload)
                    case false:
                        
                        if self?.realEstateAgent.getProperty(address: point)?.ownerUUID == gameEvent.playerSession?.playerUUID {
                            
                            let payload = OpenWindow(title: "Loading", width: 0.7, height: 100, initUrl: "/openPropertyManager.js?x=\(point.x)&y=\(point.y)", address: nil)
                            self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .openWindow, payload: payload)
                        } else {
                            let payload = OpenWindow(title: "Property info", width: 400, height: 200, initUrl: "/openPropertyInfo.js?x=\(point.x)&y=\(point.y)", address: point)
                            self?.websocketHandler.sendTo(playerSessionID: gameEvent.playerSession?.id, commandType: .openWindow, payload: payload)
                        }
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
