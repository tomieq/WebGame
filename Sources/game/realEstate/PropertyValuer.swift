//
//  PropertyValuer.swift
//  
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation


class PropertyValueFactors {
    public var baseLandValue: Double = 90000
    // property value loss
    public var propertyValueDistanceFromRoadLoss: Double = 0.6
    public var propertyValueAntennaSurroundingLoss: Double = 0.22
    // property value gain
    public var propertyValueDistanceFromResidentialBuildingGain: Double = 0.2
}

class PropertyValuer {
    let mapManager: GameMapManager
    let dataStore: DataStoreProvider
    let valueFactors: PropertyValueFactors
    
    init(mapManager: GameMapManager, dataStore: DataStoreProvider) {
        self.mapManager = mapManager
        self.dataStore = dataStore
        self.valueFactors = PropertyValueFactors()
    }
    
    private func estimateLandValue(_ address: MapPoint) -> Double {
        return (self.valueFactors.baseLandValue * self.calculateLocationValueFactor(address)).rounded(toPlaces: 0)
    }
    
    private func estimateRoadValue(_ address: MapPoint) -> Double {
        return 0
    }
    
    private func estimateResidentialBuildingValue(_ address: MapPoint) -> Double {
        return 10
    }
    
    func estimateValue(_ address: MapPoint) -> Double? {
        
        guard let tile = self.mapManager.map.getTile(address: address) else {
            return self.estimateLandValue(address)
        }
        guard let propertyType = tile.propertyType else {
            return nil
        }
        switch propertyType {
        case .land:
            return self.estimateLandValue(address)
        case .road:
            return self.estimateRoadValue(address)
        case .residentialBuilding:
            return self.estimateResidentialBuildingValue(address)
        }
    }
    
    private func calculateLocationValueFactor(_ address: MapPoint) -> Double {
        // in future add price relation to bus stop
        
        func getBuildingsFactor(_ address: MapPoint) -> Double {
            var startPrice = 1.0
            for distance in (1...4) {
                for streetAddress in self.mapManager.map.getNeighbourAddresses(to: address, radius: distance) {
                    if let tile = self.mapManager.map.getTile(address: streetAddress), tile.isStreet() {
                        
                        if distance == 1 {
                            
                            for buildingDistance in (1...3) {
                                var numberOfBuildings = 0
                                for buildingAddress in self.mapManager.map.getNeighbourAddresses(to: address, radius: buildingDistance) {
                                    if let tile = self.mapManager.map.getTile(address: buildingAddress), tile.isBuilding() {
                                        numberOfBuildings += 1
                                    }
                                }
                                if numberOfBuildings > 0 {
                                    let factor = self.valueFactors.propertyValueDistanceFromResidentialBuildingGain/buildingDistance.double
                                    startPrice = startPrice * (1 + numberOfBuildings.double * factor)
                                }
                            }
                        }
                        return startPrice
                    }
                }
                startPrice = startPrice * self.valueFactors.propertyValueDistanceFromRoadLoss
            }
            return startPrice
        }
        
        func getAntennaFactor(_ address: MapPoint) -> Double {
            var startPrice = 1.0
            for distance in (1...3) {
                for streetAddress in self.mapManager.map.getNeighbourAddresses(to: address, radius: distance) {
                    if let tile = self.mapManager.map.getTile(address: streetAddress), tile.isAntenna() {
                        startPrice = startPrice * self.valueFactors.propertyValueAntennaSurroundingLoss * distance.double
                    }
                }
            }
            return startPrice
        }
        return getBuildingsFactor(address) * getAntennaFactor(address) * (1 + self.mapManager.occupiedSpaceOnMap())
    }
}
