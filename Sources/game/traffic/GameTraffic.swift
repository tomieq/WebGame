//
//  GameTraffic.swift
//  
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation
import RxSwift
import RxCocoa

enum GameTrafficEvent {
    case vehicleTravel(VehicleTravelData)
}

enum GameTrafficRequest {
    case requestVehicleTravel(start: MapPoint, end: MapPoint)
    case vehicleTravelFinished(id: String)
}

class GameTraffic {
    let gameMap: GameMap
    let streetNavi: StreetNavi
    let events = PublishSubject<GameTrafficEvent>()
    let disposeBag = DisposeBag()
    
    
    init(gameMap: GameMap) {
        self.gameMap = gameMap
        self.streetNavi = StreetNavi(gameMap: self.gameMap)
        self.startRandomTraffic()
    }
    
    private func startRandomTraffic() {
        
        var buildingPoints = self.gameMap.gameTiles.filter{ tile in
            if case .building = tile.type { return true }
            return false
        }
        
        Observable<Int>.interval(.seconds(10), scheduler: MainScheduler.instance).bind { [weak self] _ in
            
            buildingPoints.shuffle()
            if let startBuilding = buildingPoints.first?.address,
                let endBuilding = buildingPoints.last?.address,
                let startPoint = self?.streetNavi.findNearestStreetPoint(for: startBuilding),
                let endPoint = self?.streetNavi.findNearestStreetPoint(for: endBuilding),
                let travelPoints = self?.streetNavi.routePoints(from: startPoint, to: endPoint) {
                let travelData = VehicleTravelData(id: UUID().uuidString, speed: 8, vehicleType: "car\(Int.random(in: 1...2))", travelPoints: travelPoints)
                self?.events.onNext(.vehicleTravel(travelData))
            }
        }.disposed(by: self.disposeBag)
        
    }
}
