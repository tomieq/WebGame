//
//  AddonsMap.swift
//  
//
//  Created by Tomasz Kucharski on 14/02/2022.
//

import Foundation

protocol AddonsMapDelegate {
    func reloadAddonsMap()
}

struct AddonMapTile {
    let address: MapPoint
    let type: AddonTileType
}

class AddonsMap {
    private var addonTiles: [MapPoint:AddonMapTile] = [:]
    private var parkingClientCalculator: ParkingClientCalculator
    var delegate: AddonsMapDelegate?
    var tiles: [AddonMapTile] {
        return Array(self.addonTiles.values)
    }
    
    init(parkingClientCalculator: ParkingClientCalculator) {
        self.parkingClientCalculator = parkingClientCalculator
        
        self.syncMapTiles()
    }
    
    private func syncMapTiles() {
        self.addonTiles = [:]
        for tile in self.parkingClientCalculator.mapManager.map.tiles {
            let address = tile.address
            switch tile.type {
            case .parking(let parkingType):
                let carsOnParking = self.parkingClientCalculator.calculateCarsForParking(address: address)
                if carsOnParking > 0 {
                    print("There are \(carsOnParking) at address \(address.readable)")
                    let size = max(min(10, Int(carsOnParking/5)), 1)
                    self.addonTiles[address] = AddonMapTile(address: address, type: .carsOnParking(direction: parkingType.direction, size: size))
                }
            default:
                break
            }
        }
        self.delegate?.reloadAddonsMap()
    }
    
    func constructionFinished(_ types: [ConstructionType]) {
        if types.contains(.parking) {
            self.syncMapTiles()
        }
    }
}

fileprivate extension ParkingType {
    var direction: CarsOnParkingDirection {
        switch self {
            
        case .bottomConnection:
            return .Y
        case .topConnection:
            return .Y
        case .leftConnection:
            return .X
        case .rightConnection:
            return .X
        case .X:
            return .X
        case .Y:
            return .Y
        }
    }
}
