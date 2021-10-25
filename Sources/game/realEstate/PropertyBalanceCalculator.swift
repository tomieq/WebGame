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
    let monthlyCosts: MonthlyCostPriceList
    
    init(mapManager: GameMapManager, dataStore: DataStoreProvider) {
        self.mapManager = mapManager
        self.dataStore = dataStore
        self.monthlyCosts = MonthlyCostPriceList()
    }
    
    func getMontlyCosts(address: MapPoint) -> [MonthlyCost] {
        guard let tile = self.mapManager.map.getTile(address: address) else {
            let price = self.monthlyCosts.montlyLandCost.rounded(toPlaces: 0)
            return [MonthlyCost(name: "Bills", price: price)]
        }
        guard let propertyType = tile.propertyType else {
            return []
        }
        switch propertyType {
            
        case .land:
            let price = self.monthlyCosts.montlyLandCost.rounded(toPlaces: 0)
            return [MonthlyCost(name: "Bills", price: price)]
        case .road:
            let price = self.monthlyCosts.montlyRoadCost.rounded(toPlaces: 0)
            return [MonthlyCost(name: "Maintenance", price: price)]
        case .residentialBuilding:
            let bills = self.monthlyCosts.montlyResidentialBuildingCost.rounded(toPlaces: 0)
            switch tile.type {
            case .building(let size):
                let maintenance = (self.monthlyCosts.montlyResidentialBuildingCostPerStorey * size.double).rounded(toPlaces: 0)
                return [MonthlyCost(name: "Bills", price: bills), MonthlyCost(name: "Maintenance", price: maintenance)]
            case .buildingUnderConstruction(_):
                return [MonthlyCost(name: "Bills", price: bills)]
            default:
                return []
            }
        }
    }
}


class MonthlyCostPriceList {
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


struct MonthlyCost {
    let name: String
    let price: Double
}
