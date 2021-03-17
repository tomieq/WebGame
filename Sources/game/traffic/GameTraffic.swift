//
//  GameTraffic.swift
//  
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation
import RxSwift
import RxCocoa


class GameTraffic {
    let gameMap: GameMap
    let streetNavi: StreetNavi
    private let disposeBag = DisposeBag()
    private var runningCars: [PlayerSession:[VehicleTravelStarted]]
    
    
    init(gameMap: GameMap) {
        self.gameMap = gameMap
        self.runningCars = [:]
        self.streetNavi = StreetNavi(gameMap: self.gameMap)
        self.startRandomTraffic()
        
        GameEventBus.gameEvents.asObservable().bind { [weak self] event in
            guard let session = event.playerSession else { return }
            switch event.action {
                
            case .userConnected:
                self?.runningCars[session] = []
            case .userDisconnected:
                self?.runningCars[session] = nil
            case .vehicleTravelFinished(let payload):
                self?.runningCars[session] = self?.runningCars[session]?.filter { $0.id != payload.id } ?? []
            default:
                break
            }
        }.disposed(by: self.disposeBag)
    }
    
    private func startRandomTraffic() {
        
        var buildingPoints = self.gameMap.gameTiles.filter{ tile in
            if case .building = tile.type { return true }
            return false
        }
        
        Observable<Int>.interval(.seconds(10), scheduler: MainScheduler.instance).bind { [weak self] _ in
            
            self?.runningCars.forEach { (session, vehicleList) in
                if vehicleList.count < 4 {
                    (0...(4-vehicleList.count)).forEach { _ in 
                        buildingPoints.shuffle()
                        if let startBuilding = buildingPoints.first?.address,
                            let endBuilding = buildingPoints.last?.address,
                            let startPoint = self?.streetNavi.findNearestStreetPoint(for: startBuilding),
                            let endPoint = self?.streetNavi.findNearestStreetPoint(for: endBuilding),
                            let travelPoints = self?.streetNavi.routePoints(from: startPoint, to: endPoint) {
                            let payload = VehicleTravelStarted(id: UUID().uuidString, speed: 8, vehicleType: "car\(Int.random(in: 1...2))", travelPoints: travelPoints)
                            let event = GameEvent(playerSession: session, action: .vehicleTravelStarted(payload))
                            self?.runningCars[session]?.append(payload)
                            GameEventBus.gameEvents.onNext(event)
                        }
                    }
                }
            }
            
        }.disposed(by: self.disposeBag)
        
    }
}
