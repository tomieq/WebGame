//
//  PropertyValuer.swift
//  
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation


class PropertyValueFactors {
    public var baseLandValue: Double = 90000
    public var roadValueFactor: Double = 0.3
    // property value loss
    public var propertyValueDistanceFromRoadLoss: Double = 0.6
    public var propertyValueAntennaSurroundingLoss: Double = 0.22
    // property value gain
    public var propertyValueDistanceFromResidentialBuildingGain: Double = 0.2
    public var residentialBuildingReadyPriceGain: Double = 1.2
}

class PropertyValuer {
    let mapManager: GameMapManager
    let dataStore: DataStoreProvider
    let valueFactors: PropertyValueFactors
    let balanceCalculator: PropertyBalanceCalculator
    let constructionServices: ConstructionServices
    
    init(balanceCalculator: PropertyBalanceCalculator, constructionServices: ConstructionServices) {
        self.mapManager = balanceCalculator.mapManager
        self.dataStore = constructionServices.dataStore
        self.constructionServices = constructionServices
        self.balanceCalculator = balanceCalculator
        self.valueFactors = PropertyValueFactors()
    }
    
    private func estimateLandValue(_ address: MapPoint) -> Double {
        return (self.valueFactors.baseLandValue * self.calculateLocationValueFactor(address)).rounded(toPlaces: 0)
    }
    
    private func estimateRoadValue(_ address: MapPoint) -> Double {
        return (self.estimateLandValue(address) * self.valueFactors.roadValueFactor).rounded(toPlaces: 0)
    }
    
    private func estimateParkingValue(_ address: MapPoint) -> Double {
        let constructionOffer = self.constructionServices.parkingOffer(landName: "")
        let monthlyCost = self.balanceCalculator.getParkingUnderConstructionMontlyCosts().map{ $0.netValue }.reduce(0, +)
        let costs = constructionOffer.duration.double * monthlyCost
        var basePrice = constructionOffer.invoice.netValue + costs + self.estimateLandValue(address)
        let carsOnTheparking = self.balanceCalculator.parkingClientCalculator.calculateCarsForParking(address: address)
        basePrice += carsOnTheparking * self.balanceCalculator.incomePriceList.monthlyParkingIncomePerTakenPlace * 3
        return basePrice.rounded(toPlaces: 0)
    }
    
    private func estimateResidentialBuildingValue(_ address: MapPoint) -> Double {
        guard let building: ResidentialBuilding = self.dataStore.find(address: address) else { return 0 }
        let constructionOffer = self.constructionServices.residentialBuildingOffer(landName: "", storeyAmount: building.storeyAmount, elevator: building.hasElevator, balconies: building.balconies)
        let monthlyCost = self.balanceCalculator.getBuildingUnderConstructionMontlyCosts().map{ $0.netValue }.reduce(0, +)
        let costs = constructionOffer.duration.double * monthlyCost
        let basePrice = constructionOffer.invoice.netValue + costs + self.estimateLandValue(address)
        return (basePrice * self.valueFactors.residentialBuildingReadyPriceGain).rounded(toPlaces: 0)
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
        case .parking:
            return self.estimateParkingValue(address)
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
                                    if let tile = self.mapManager.map.getTile(address: buildingAddress), (tile.isBuilding() || tile.isOffice()) {
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
