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
        
        Observable<Int>.interval(.seconds(20), scheduler: MainScheduler.instance).bind { [weak self] _ in
            if let travelPoints = self?.streetNavi.routePoints(from: MapPoint(x: 0, y: 16), to: MapPoint(x: 24, y: 16)) {
                let travelData = VehicleTravelData(id: UUID().uuidString, speed: 10, vehicleType: "car2", travelPoints: travelPoints)
                self?.events.onNext(.vehicleTravel(travelData))
            }
        }.disposed(by: self.disposeBag)
        
    }
}
