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
    
    func getMonthlyIncome(address: MapPoint) -> [MonthlyIncome] {
        return []
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
            return self.getLandMontlyCosts()
        case .road:
            let maintenance = Invoice(title: "Maintenance", netValue: self.priceList.montlyRoadMaintenanceCost, taxRate: self.taxRates.servicesTax)
            return [maintenance]
        case .parking:
            switch tile.type {
            case .parking(_):
                return self.getParkingMontlyCosts()
            case .parkingUnderConstruction:
                return self.getParkingUnderConstructionMontlyCosts()
            default:
                return []
            }
        case .residentialBuilding:
            
            switch tile.type {
            case .building(let size):
                return self.getBuildingMontlyCosts(size: size)
            case .buildingUnderConstruction(_):
                return self.getBuildingUnderConstructionMontlyCosts()
            default:
                return []
            }
        }
    }
    
    func getLandMontlyCosts() -> [Invoice] {
        let water = Invoice(title: "Water constant bill", netValue: self.priceList.montlyLandWaterCost, taxRate: self.taxRates.waterBillTax)
        let electricity = Invoice(title: "Electricity constant bill", netValue: self.priceList.montlyLandElectricityCost, taxRate: self.taxRates.electricityBillTax)
        let maintenance = Invoice(title: "Maintenance", netValue: self.priceList.montlyLandMaintenanceCost, taxRate: self.taxRates.servicesTax)
        return [water, electricity, maintenance]
    }
    
    func getParkingUnderConstructionMontlyCosts() -> [Invoice] {
        let water = Invoice(title: "Water bill", netValue: self.priceList.montlyParkingUnderConstructionWaterCost, taxRate: self.taxRates.waterBillTax)
        let electricity = Invoice(title: "Electricity bill", netValue: self.priceList.monthlyResidentialBuildingOwnerIncomePerFlat, taxRate: self.taxRates.electricityBillTax)
        return [water, electricity]
    }
    
    func getParkingMontlyCosts() -> [Invoice] {
        let security = Invoice(title: "Security costs", netValue: self.priceList.montlyParkingSecurityCost, taxRate: self.taxRates.waterBillTax)
        let electricity = Invoice(title: "Electricity bill", netValue: self.priceList.montlyParkingElectricityCost, taxRate: self.taxRates.electricityBillTax)
        return [security, electricity]
    }
    
    func getBuildingMontlyCosts(size: Int) -> [Invoice] {
        let water = Invoice(title: "Water bill", netValue: self.priceList.montlyResidentialBuildingWaterCost, taxRate: self.taxRates.waterBillTax)
        let electricity = Invoice(title: "Electricity bill", netValue: self.priceList.montlyResidentialBuildingElectricityCost, taxRate: self.taxRates.electricityBillTax)
        let maintenance = Invoice(title: "Maintenance", netValue: self.priceList.montlyResidentialBuildingMaintenanceCostPerStorey  * size.double, taxRate: self.taxRates.servicesTax)
        
        return [water, electricity, maintenance]
    }
    
    func getBuildingUnderConstructionMontlyCosts() -> [Invoice] {
        let water = Invoice(title: "Water bill", netValue: self.priceList.montlyResidentialBuildingUnderConstructionWaterCost, taxRate: self.taxRates.waterBillTax)
        let electricity = Invoice(title: "Electricity bill", netValue: self.priceList.montlyResidentialBuildingUnderConstructionElectricityCost, taxRate: self.taxRates.electricityBillTax)
        return [water, electricity]
    }
}


class MonthlyCostPriceList {
    // land
    public var montlyLandElectricityCost: Double = 30
    public var montlyLandWaterCost: Double = 65
    public var montlyLandMaintenanceCost: Double = 250
    // road
    public var montlyRoadMaintenanceCost: Double = 580.0
    // parking under construction
    public var montlyParkingUnderConstructionElectricityCost: Double = 540.0
    public var montlyParkingUnderConstructionWaterCost: Double = 189.0
    // parking
    public var montlyParkingElectricityCost: Double = 210.0
    public var montlyParkingSecurityCost: Double = 305.0
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

struct MonthlyIncome {
    let name: String
    let netValue: Double
}
