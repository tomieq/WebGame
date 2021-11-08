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
    let parkingBusiness: ParkingBusiness
    let propertyBalanceCalculator: PropertyBalanceCalculator
    let gameClock: GameClock
    let clickRouter: ClickTileRouter
    let investorAI: InvestorArtifficialIntelligence
    let footballBookie: FootballBookie
    let court: Court
    let police: Police
    let debtCollector: DebtCollector
    let reloadMapCoordinator: ReloadMapCoordinator
    let syncWalletCoordinator: SyncWalletCoordinator
    let disposeBag = DisposeBag()
    
    init(dataStore: DataStoreProvider) {
        self.time = GameTime()
        self.dataStore = dataStore
        self.taxRates = TaxRates()
        self.centralbank = CentralBank(dataStore: self.dataStore, taxRates: self.taxRates, time: self.time)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: SystemPlayer.government.login, wallet: 0)
        let realEstateAgent = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: SystemPlayer.realEstateAgency.login, wallet: 0)
        let user1 = Player(uuid: "p1", login: "Tomasz Kucharski", wallet: 10000000)
        let user2 = Player(uuid: "p2", login: "Richard Smith", wallet: 10000000)
        self.dataStore.create(government)
        self.dataStore.create(realEstateAgent)
        self.dataStore.create(user1)
        self.dataStore.create(user2)
        
        let investor = Player(uuid: SystemPlayer.investor.uuid, login: SystemPlayer.investor.login, wallet: 1000000000)
        self.dataStore.create(investor)
        
        let bookie = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 1000000000)
        self.dataStore.create(bookie)
        
        self.gameMap = GameMap(width: 35, height: 35, scale: 0.30)
        self.gameMapManager = GameMapManager(self.gameMap)
        self.gameMapManager.loadMapFrom(path: "maps/roadMap1")
        
        MapStorageSync(mapManager: self.gameMapManager, dataStore: self.dataStore).syncMapWithDataStore()
        
        self.parkingBusiness = ParkingBusiness(mapManager: self.gameMapManager, dataStore: self.dataStore, time: self.time)
        self.propertyBalanceCalculator = PropertyBalanceCalculator(mapManager: self.gameMapManager, parkingBusiness: self.parkingBusiness, taxRates: self.taxRates)
        
        self.constructionServices = ConstructionServices(mapManager: self.gameMapManager, centralBank: self.centralbank, time: self.time)
        self.propertyValuer = PropertyValuer(balanceCalculator: self.propertyBalanceCalculator, constructionServices: self.constructionServices)
        self.realEstateAgent = RealEstateAgent(mapManager: self.gameMapManager, propertyValuer: self.propertyValuer, centralBank: self.centralbank)
        
        
        self.streetNavi = StreetNavi(gameMap: self.gameMap)
        self.gameTraffic = GameTraffic(streetNavi: self.streetNavi)
        self.websocketHandler = WebsocketHandler()
        self.gameClock = GameClock(realEstateAgent: self.realEstateAgent, time: self.time, secondsPerMonth: 30)
        
        self.clickRouter = ClickTileRouter(agent: self.realEstateAgent)
        self.investorAI = InvestorArtifficialIntelligence(agent: self.realEstateAgent)
        self.footballBookie = FootballBookie(centralBank: self.centralbank)
        
        self.court = Court(centralbank: self.centralbank)
        self.police = Police(footballBookie: self.footballBookie, court: self.court)
        self.debtCollector = DebtCollector(realEstateAgent: self.realEstateAgent)
        
        self.reloadMapCoordinator = ReloadMapCoordinator()
        self.syncWalletCoordinator = SyncWalletCoordinator()
        
        self.realEstateAgent.delegate = self
        self.constructionServices.delegate = self
        self.gameClock.delegate = self
        self.footballBookie.delegate = self
        self.court.delegate = self
        self.police.delegate = self
        self.debtCollector.delegate = self
        self.parkingBusiness.delegate = self
        
        self.reloadMapCoordinator.setFlushAction { [weak self] in
           self?.streetNavi.reload()
           self?.gameTraffic.mapReloaded()
           self?.websocketHandler.sendToAll(command: .reloadMap)
       }
        
        self.syncWalletCoordinator.setSyncWalletChange { [weak self] playerUUID in
            if let player: Player = self?.dataStore.find(uuid: playerUUID) {
                for session in PlayerSessionManager.shared.getSessions(playerUUID: playerUUID){
                    self?.websocketHandler.sendTo(playerSessionID: session.id, command: .updateWallet(player.wallet.money))
                }
            }
        }

        self.setupDevParams()

        GameEventBus.gameEvents.asObservable().bind { [weak self] gameEvent in
            switch gameEvent.action {
            case .userConnected:
                if let session = gameEvent.playerSession, let player: Player = self?.dataStore.find(uuid: session.playerUUID) {
                    self?.websocketHandler.sendTo(playerSessionID: session.id, command: .updateWallet(player.wallet.money))
                    if let text = self?.gameClock.time.text, let secondsLeft = self?.gameClock.secondsLeft {
                        self?.websocketHandler.sendTo(playerSessionID: session.id, command: .updateGameDate(UIGameDate(text: text, secondsLeft: secondsLeft)))
                    }
                }
            case .userDisconnected:
                if let session = gameEvent.playerSession {
                    PlayerSessionManager.shared.destroyPlayerSession(playerSessionID: session.id)
                }
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
                    self?.notifyEveryone(payload)
                case .some(let playerSession):
                    self?.notify(playerUUID: playerSession.playerUUID, payload)
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

extension GameEngine: ParkingBusinessDelegate {}
extension GameEngine: CourtDelegate {}
extension GameEngine: PoliceDelegate {}
extension GameEngine: DebtCollectorDelegate {}
extension GameEngine: FootballBookieDelegate {
    func notify(playerUUID: String, _ notification: UINotification) {
        for session in PlayerSessionManager.shared.getSessions(playerUUID: playerUUID){
            self.websocketHandler.sendTo(playerSessionID: session.id, command: .notification(notification))
        }
    }
}
extension GameEngine: RealEstateAgentDelegate, ConstructionServicesDelegate {
    
    func syncWalletChange(playerUUID: String) {
        self.syncWalletCoordinator.syncWalletChange(playerUUID: playerUUID)
    }
    
    func reloadMap() {
        self.reloadMapCoordinator.reloadMap()
    }
    
    func notifyEveryone(_ notification: UINotification) {
        self.websocketHandler.sendToAll(command: .notification(notification))
    }

    func notifyEveryone(_ notification: UINotification, exceptUserUUIDs: [String] = []) {
        self.websocketHandler.sendToAll(command: .notification(notification), exceptUserUUIDs: exceptUserUUIDs)
    }
}

extension GameEngine: GameClockDelegate {
    func nextMonth() {
        self.reloadMapCoordinator.hold()
        self.syncWalletCoordinator.hold()
        
        self.debtCollector.executeDebts()
        self.constructionServices.finishInvestments()
        self.investorAI.purchaseBargains()
        self.footballBookie.nextMonth()
        
        self.police.checkFootballMatches()
        self.court.processTrials()
        self.parkingBusiness.monthlyActions()
        
        self.reloadMapCoordinator.flush()
        self.syncWalletCoordinator.flush()
        self.websocketHandler.sendToAll(command: .updateGameDate(UIGameDate(text: self.time.text, secondsLeft: self.gameClock.secondsLeft)))
        
        let delay = Int.random(in: 3...(self.gameClock.secondsPerMonth - 3))
        Observable<Int>.interval(.seconds(delay), scheduler: MainScheduler.instance)
            .take(1)
            .bind { [weak self] number in
                guard let `self` = self else { return }
                self.parkingBusiness.randomDamage()
            
        }.disposed(by: self.disposeBag)
    }

    func syncTime() {
        self.websocketHandler.sendToAll(command: .updateGameDate(UIGameDate(text: self.time.text, secondsLeft: self.gameClock.secondsLeft)))
    }
    
}
