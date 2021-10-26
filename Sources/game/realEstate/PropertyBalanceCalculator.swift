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
    let priceList: MonthlyCostPriceList
    let taxRates: TaxRates
    
    init(mapManager: GameMapManager, dataStore: DataStoreProvider, taxRates: TaxRates) {
        self.mapManager = mapManager
        self.dataStore = dataStore
        self.priceList = MonthlyCostPriceList()
        self.taxRates = taxRates
    }
    
    func getMontlyCosts(address: MapPoint) -> [Invoice] {
        guard let tile = self.mapManager.map.getTile(address: address) else {
            return []
        }
        guard let propertyType = tile.propertyType else {
            return []
        }
        switch propertyType {
            
        case .land:
            let water = Invoice(title: "Water bill", netValue: self.priceList.montlyLandWaterCost, taxRate: self.taxRates.waterBillTax)
            let electricity = Invoice(title: "Electricity bill", netValue: self.priceList.montlyLandElectricityCost, taxRate: self.taxRates.electricityBillTax)
            let maintenance = Invoice(title: "Maintenance", netValue: self.priceList.montlyLandMaintenanceCost, taxRate: self.taxRates.valueAddedTax)
            return [water, electricity, maintenance]
        case .road:
            let maintenance = Invoice(title: "Maintenance", netValue: self.priceList.montlyRoadMaintenanceCost, taxRate: self.taxRates.valueAddedTax)
            return [maintenance]
        case .residentialBuilding:
            
            switch tile.type {
            case .building(let size):
                let water = Invoice(title: "Water bill", netValue: self.priceList.montlyResidentialBuildingWaterCost, taxRate: self.taxRates.waterBillTax)
                let electricity = Invoice(title: "Electricity bill", netValue: self.priceList.montlyResidentialBuildingElectricityCost, taxRate: self.taxRates.electricityBillTax)
                let maintenance = Invoice(title: "Maintenance", netValue: self.priceList.montlyResidentialBuildingMaintenanceCostPerStorey  * size.double, taxRate: self.taxRates.valueAddedTax)
                
                return [water, electricity, maintenance]
            case .buildingUnderConstruction(_):
                let water = Invoice(title: "Water bill", netValue: self.priceList.montlyResidentialBuildingUnderConstructionWaterCost, taxRate: self.taxRates.waterBillTax)
                let electricity = Invoice(title: "Electricity bill", netValue: self.priceList.montlyResidentialBuildingUnderConstructionElectricityCost, taxRate: self.taxRates.electricityBillTax)
                return [water, electricity]
            default:
                return []
            }
        }
    }
}


class MonthlyCostPriceList {
    // land
    public var montlyLandElectricityCost: Double = 30
    public var montlyLandWaterCost: Double = 65
    public var montlyLandMaintenanceCost: Double = 250
    // road
    public var montlyRoadMaintenanceCost: Double = 580.0
    // residential building under construction
    public var montlyResidentialBuildingUnderConstructionElectricityCost: Double = 3700.0
    public var montlyResidentialBuildingUnderConstructionWaterCost: Double = 1800
    // residential building
    public var montlyResidentialBuildingElectricityCost: Double = 1300.0
    public var montlyResidentialBuildingWaterCost: Double = 320.0
    public var montlyResidentialBuildingMaintenanceCostPerStorey: Double = 400.0
    
    public var monthlyResidentialBuildingOwnerIncomePerFlat: Double = 300.0
    public var monthlyBillsForRentedApartment: Double = 452.0
    public var monthlyBillsForUnrentedApartment: Double = 180.0
    public var monthlyApartmentRentalFee: Double = 2300
    public var monthlyApartmentBuildingOwnerFee: Double = 930
}
