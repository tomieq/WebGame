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
        
        let carsPerAddress = self.getCarsAroundAddress(address)
        let competitors = self.getParkingsAroundAddress(address)
        // sharedCars stores cars shared by multiple parkings. Address -> number of parkings
        var sharedCars: [MapPoint: Int] = [:]
        
        for competitor in competitors {
            let carsInCompetitorRange = self.getCarsAroundAddress(competitor)
            for address in carsInCompetitorRange.keys {
                sharedCars[address] = (sharedCars[address] ?? 1) + 1
            }
        }
        var amountOfCars: Double = 0
        for (address, numberOfCars) in carsPerAddress {
            if let amountOfCompetitors = sharedCars[address] {
                amountOfCars += numberOfCars / amountOfCompetitors.double
            } else {
                amountOfCars += numberOfCars
            }
        }
    
        return amountOfCars
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
        for radius in (1...4) {
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
