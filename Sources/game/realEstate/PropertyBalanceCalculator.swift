//
//  PropertyBalanceCalculator.swift
//  
//
//  Created by Tomasz Kucharski on 23/10/2021.
//

import Foundation

class PropertyBalanceCalculator {
    let mapManager: GameMapManager
    let dataStore: DataStoreProvider
    let monthlyCosts: MonthlyCosts
    
    init(mapManager: GameMapManager, dataStore: DataStoreProvider) {
        self.mapManager = mapManager
        self.dataStore = dataStore
        self.monthlyCosts = MonthlyCosts()
    }
    
    func getMontlyCosts(address: MapPoint) -> Double {
        guard let tile = self.mapManager.map.getTile(address: address) else {
            return self.monthlyCosts.montlyLandCost.rounded(toPlaces: 0)
        }
        guard let propertyType = tile.propertyType else {
            return 0
        }
        switch propertyType {
            
        case .land:
            return self.monthlyCosts.montlyLandCost.rounded(toPlaces: 0)
        case .road:
            return self.monthlyCosts.montlyRoadCost.rounded(toPlaces: 0)
        case .residentialBuilding:
            switch tile.type {
            case .building(let size):
                return (self.monthlyCosts.montlyResidentialBuildingCost + self.monthlyCosts.montlyResidentialBuildingCostPerStorey * size.double).rounded(toPlaces: 0)
            case .buildingUnderConstruction(_):
                return self.monthlyCosts.montlyResidentialBuildingCost.rounded(toPlaces: 0)
            default:
                return 0
            }
        }
    }
}


class MonthlyCosts {
    // montly costs
    public var montlyLandCost: Double = 110.0
    public var montlyRoadCost: Double = 580.0
    public var montlyResidentialBuildingCost: Double = 1300.0
    public var montlyResidentialBuildingCostPerStorey: Double = 1100.0
    public var monthlyResidentialBuildingOwnerIncomePerFlat: Double = 300.0
    public var monthlyBillsForRentedApartment: Double = 452.0
    public var monthlyBillsForUnrentedApartment: Double = 180.0
    public var monthlyApartmentRentalFee: Double = 2300
    public var monthlyApartmentBuildingOwnerFee: Double = 930
}
