//
//  ParkingBusiness.swift
//  
//
//  Created by Tomasz Kucharski on 05/11/2021.
//

import Foundation

protocol ParkingBusinessDelegate {
    func notify(playerUUID: String, _ notification: UINotification)
}

class ParkingBusiness {
    let mapManager: GameMapManager
    let dataStore: DataStoreProvider
    var delegate: ParkingBusinessDelegate?
    private var damages: [MapPoint: [ParkingDamage]] = [:]
    
    init(mapManager: GameMapManager, dataStore: DataStoreProvider) {
        self.mapManager = mapManager
        self.dataStore = dataStore
    }
    
    func addDamage(_ parkingDamage: ParkingDamage, address: MapPoint) {
        if self.damages[address] != nil {
            self.damages[address]?.append(parkingDamage)
        } else {
            self.damages[address] = [parkingDamage]
        }
        if let parking: Parking = self.dataStore.find(address: address) {
            let trustLevel = parking.trustLevel - parkingDamage.type.trustLoose
            self.dataStore.update(ParkingMutation(uuid: parking.uuid, attributes: [.trustLevel(trustLevel)]))
            if parking.insurance.damageCoverLimit > parkingDamage.fixPrice {
                // TODO: 
            }
        }
    }
    
    func calculateCarsForParking(address: MapPoint) -> Double {
        
        let parking: Parking? = self.dataStore.find(address: address)
        let carsInTheArea = self.getCarsAroundAddress(address)
        let competitorAddresses = self.getParkingsAroundAddress(address)
        let competitors: [Parking] = competitorAddresses.compactMap{ self.dataStore.find(address: $0) }
        // competitorTrusts stores a map of competitor's shares for address (competitors' parking trusts)
        var competitorTrusts: [MapPoint: [Double]] = [:]
        
        for competitorAddress in competitorAddresses {
            let carsInCompetitorRange = self.getCarsAroundAddress(competitorAddress)
            let competitorTrust = competitors.first{ $0.address == competitorAddress }?.trustLevel ?? 1.0
            for address in carsInCompetitorRange.keys {
                if competitorTrusts[address] != nil {
                    competitorTrusts[address]?.append(competitorTrust)
                } else {
                    competitorTrusts[address] = [competitorTrust]
                }
            }
        }
        let myTrust = parking?.trustLevel ?? 1.0
        var amountOfCars: Double = 0
        for (address, numberOfCars) in carsInTheArea {
            if let trusts = competitorTrusts[address] {
                let sumOfTrust = myTrust + trusts.reduce(0, +)
                amountOfCars += numberOfCars * (myTrust / sumOfTrust)
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
                    let carsOnProperty = tileType.carsOnProperty
                    if carsOnProperty > 0 {
                        carsPerAddress[neighbour] = tileType.carsOnProperty
                    }
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
    
    var damageCoverLimit: Double {
        switch self {
            
        case .none:
            return 0
        case .basic:
            return self.monthlyFee * 2
        case .extended:
            return self.monthlyFee * 3
        case .full:
            return 100000
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
            return 0.05
        case .localNewspaperAd:
            return 0.15
        case .radioAd:
            return 0.25
        case .tvSpot:
            return 0.35
        }
    }
}
