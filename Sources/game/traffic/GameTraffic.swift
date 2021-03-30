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
    private var buildingPoints: [MapPoint]
    
    
    init(gameMap: GameMap) {
        self.gameMap = gameMap
        self.runningCars = [:]
        self.streetNavi = StreetNavi(gameMap: self.gameMap)
        self.buildingPoints = self.gameMap.tiles.filter{ $0.isBuilding() }.map{ $0.address }
        self.startRandomTraffic()
        
        GameEventBus.gameEvents.asObservable().bind { [weak self] event in
            
            switch event.action {
                
            case .userConnected:
                guard let session = event.playerSession else { return }
                self?.runningCars[session] = []
            case .userDisconnected:
                guard let session = event.playerSession else { return }
                self?.runningCars[session] = nil
            case .vehicleTravelFinished(let payload):
                guard let session = event.playerSession else { return }
                self?.runningCars[session] = self?.runningCars[session]?.filter { $0.id != payload.id } ?? []
            case .reloadMap:
                self?.buildingPoints = self?.gameMap.tiles.filter{ $0.isBuilding() }.map{ $0.address } ?? []
            default:
                break
            }
        }.disposed(by: self.disposeBag)
    }
    
    private func startRandomTraffic() {
        
        Observable<Int>.interval(.seconds(10), scheduler: MainScheduler.instance).bind { [weak self] _ in
            
            for (session, vehicleList) in self?.runningCars ?? [:] {
                if vehicleList.count < 4 {
                    for _ in (0...(4-vehicleList.count)) { 
                        self?.buildingPoints.shuffle()
                        if let startBuilding = self?.buildingPoints.first,
                            let endBuilding = self?.buildingPoints.last,
                            startBuilding != endBuilding,
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
