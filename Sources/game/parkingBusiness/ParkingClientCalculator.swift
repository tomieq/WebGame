//
//  ParkingClientCalculator.swift
//
//
//  Created by Tomasz Kucharski on 14/02/2022.
//

import Foundation

class ParkingClientCalculator {
    let mapManager: GameMapManager
    let dataStore: DataStoreProvider

    init(mapManager: GameMapManager, dataStore: DataStoreProvider) {
        self.mapManager = mapManager
        self.dataStore = dataStore
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
                competitorTrusts[address, default: []].append(competitorTrust)
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
