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

enum ParkingInsurance: String, CaseIterable {
    case none
    case basic
    case extended
    case full
    
    var monthlyFee: Double {
        switch self {
        case .none:
            return 0
        case .basic:
            return 280
        case .extended:
            return 620
        case .full:
            return 1380
        }
    }
    
    var name: String {
        switch self {
        case .none:
            return "No insurance"
        case .basic:
            return "Basic insurance"
        case .extended:
            return "Extended insurance"
        case .full:
            return "Full insurance"
        }
    }
}

enum ParkingSecurity: String, CaseIterable {
    case none
    case cctv
    case securityGuard
    
    var monthlyFee: Double {
        switch self {
        case .none:
            return 0
        case .cctv:
            return 520
        case .securityGuard:
            return 4300
        }
    }
    var name: String {
        switch self {
        case .none:
            return "No security"
        case .cctv:
            return "CCTV"
        case .securityGuard:
            return "Security guard 24/7"
        }
    }
}

enum ParkingAdvertising: String, CaseIterable {
    case none
    case leaflets
    case localNewspaperAd
    case radioAd
    case tvSpot
    
    var monthlyFee: Double {
        switch self {
        case .none:
            return 0
        case .leaflets:
            return 210
        case .localNewspaperAd:
            return 490
        case .radioAd:
            return 920
        case .tvSpot:
            return 2100
        }
    }
    var name: String {
        switch self {
        case .none:
            return "No advertising"
        case .leaflets:
            return "Leaflets to local area"
        case .localNewspaperAd:
            return "Advert in local newspaper"
        case .radioAd:
            return "Advert in local radio station"
        case .tvSpot:
            return "TV spot in local station"
        }
    }
    var monthlyTrustGain: Double {
        switch self {
        case .none:
            return 0
        case .leaflets:
            return 5
        case .localNewspaperAd:
            return 15
        case .radioAd:
            return 25
        case .tvSpot:
            return 35
        }
    }
}
