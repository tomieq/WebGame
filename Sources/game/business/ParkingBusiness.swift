//
//  ParkingBusiness.swift
//  
//
//  Created by Tomasz Kucharski on 05/11/2021.
//

import Foundation


class ParkingBusiness {
    let mapManager: GameMapManager
    let dataStore: DataStoreProvider
    
    init(mapManager: GameMapManager, dataStore: DataStoreProvider) {
        self.mapManager = mapManager
        self.dataStore = dataStore
    }
    
    func calculateCarsForParking(address: MapPoint) -> Double {
        
        var carsPerAddress = self.getCarsAroundAddress(address)
        let competitors = self.getParkingsAroundAddress(address)
        
        for competitor in competitors {
            let carsInCompetitorRange = self.getCarsAroundAddress(competitor)
            for sharedAddress in carsInCompetitorRange.keys {
                carsPerAddress[sharedAddress]? /= 2
            }
        }
    
        return carsPerAddress.map{ $0.value }.reduce(0, +)
    }
    
    private func getCarsAroundAddress(_ address: MapPoint) -> [MapPoint: Double] {
        var carsPerAddress: [MapPoint: Double] = [:]
        for radius in (1...2) {
            for neighbour in self.mapManager.map.getNeighbourAddresses(to: address, radius: radius) {
                if let tileType = self.mapManager.map.getTile(address: neighbour)?.type {
                    carsPerAddress[neighbour] = tileType.carsOnProperty
                }
            }
        }
        return carsPerAddress
    }
    
    func getParkingsAroundAddress(_ address: MapPoint) -> [MapPoint] {
        var parkings: [MapPoint] = []
        for radius in (1...3) {
            for parking in self.mapManager.map.getNeighbourAddresses(to: address, radius: radius) {
                if self.mapManager.map.getTile(address: parking)?.isParking() ?? false {
                    parkings.append(parking)
                }
            }
        }
        return parkings
    }
}

extension TileType {
    var carsOnProperty: Double {
        switch self {
        case .building(let size):
            return size.double
        case .cityCouncil:
            return 5
        case .school:
            return 5
        case .hospital:
            return 12
        case .footballPitch(_):
            return 5
        case .warehouse:
            return 2
        default:
            return 0
        }
    }
}
