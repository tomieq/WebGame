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
    let costPriceList: MonthlyCostPriceList
    let incomePriceList: MontlyIncomePriceList
    let taxRates: TaxRates
    
    init(mapManager: GameMapManager, dataStore: DataStoreProvider, taxRates: TaxRates) {
        self.mapManager = mapManager
        self.dataStore = dataStore
        self.costPriceList = MonthlyCostPriceList()
        self.incomePriceList = MontlyIncomePriceList()
        self.taxRates = taxRates
    }
    
    func getMonthlyIncome(address: MapPoint) -> [MonthlyIncome] {
        guard let tile = self.mapManager.map.getTile(address: address) else {
            return []
        }
        guard let propertyType = tile.propertyType else {
            return []
        }
        switch propertyType {
            
        case .land:
            return []
        case .road:
            return []
        case .parking:
            switch tile.type {
            case .parking(_):
                return self.getParkingMontlyIncome(address: address)
            case .parkingUnderConstruction:
                return []
            default:
                return []
            }
        case .residentialBuilding:
            
            switch tile.type {
            case .building(let size):
                return []
            case .buildingUnderConstruction(_):
                return []
            default:
                return []
            }
        }
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
            let maintenance = Invoice(title: "Maintenance", netValue: self.costPriceList.montlyRoadMaintenanceCost, taxRate: self.taxRates.servicesTax)
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
        let water = Invoice(title: "Water constant bill", netValue: self.costPriceList.montlyLandWaterCost, taxRate: self.taxRates.waterBillTax)
        let electricity = Invoice(title: "Electricity constant bill", netValue: self.costPriceList.montlyLandElectricityCost, taxRate: self.taxRates.electricityBillTax)
        let maintenance = Invoice(title: "Maintenance", netValue: self.costPriceList.montlyLandMaintenanceCost, taxRate: self.taxRates.servicesTax)
        return [water, electricity, maintenance]
    }
    
    func getParkingUnderConstructionMontlyCosts() -> [Invoice] {
        let water = Invoice(title: "Water bill", netValue: self.costPriceList.montlyParkingUnderConstructionWaterCost, taxRate: self.taxRates.waterBillTax)
        let electricity = Invoice(title: "Electricity bill", netValue: self.costPriceList.monthlyResidentialBuildingOwnerIncomePerFlat, taxRate: self.taxRates.electricityBillTax)
        return [water, electricity]
    }
    
    func getParkingMontlyCosts() -> [Invoice] {
        let security = Invoice(title: "Security costs", netValue: self.costPriceList.montlyParkingSecurityCost, taxRate: self.taxRates.servicesTax)
        let electricity = Invoice(title: "Electricity bill", netValue: self.costPriceList.montlyParkingElectricityCost, taxRate: self.taxRates.electricityBillTax)
        return [security, electricity]
    }
    
    func getBuildingMontlyCosts(size: Int) -> [Invoice] {
        let water = Invoice(title: "Water bill", netValue: self.costPriceList.montlyResidentialBuildingWaterCost, taxRate: self.taxRates.waterBillTax)
        let electricity = Invoice(title: "Electricity bill", netValue: self.costPriceList.montlyResidentialBuildingElectricityCost, taxRate: self.taxRates.electricityBillTax)
        let maintenance = Invoice(title: "Maintenance", netValue: self.costPriceList.montlyResidentialBuildingMaintenanceCostPerStorey  * size.double, taxRate: self.taxRates.servicesTax)
        
        return [water, electricity, maintenance]
    }
    
    func getBuildingUnderConstructionMontlyCosts() -> [Invoice] {
        let water = Invoice(title: "Water bill", netValue: self.costPriceList.montlyResidentialBuildingUnderConstructionWaterCost, taxRate: self.taxRates.waterBillTax)
        let electricity = Invoice(title: "Electricity bill", netValue: self.costPriceList.montlyResidentialBuildingUnderConstructionElectricityCost, taxRate: self.taxRates.electricityBillTax)
        return [water, electricity]
    }
    
    func getParkingMontlyIncome(address: MapPoint) -> [MonthlyIncome] {
        let carsForParking = self.calculateCarsForParking(address: address)
        if carsForParking > 0 {
            return [MonthlyIncome(name: "Renting parking places", netValue: (carsForParking * self.incomePriceList.monthlyParkingIncomePerTakenPlace).rounded(toPlaces: 0))]
        }
        return []
    }
    
    func calculateCarsForParking(address: MapPoint) -> Double {
        
        var carsPerAddress = self.getCarsAroundAddress(address)
        let competitors = self.getParkingsAroundAddress(address)
        
        for competitor in competitors {
            let carsInCompetitorRange = self.getCarsAroundAddress(competitor)
            for sharedAddress in carsInCompetitorRange.keys {
                carsPerAddress[sharedAddress]? /= 2
            }
        }
    
        return carsPerAddress.map{ $0.value }.reduce(0, +)
    }
    
    private func getCarsAroundAddress(_ address: MapPoint) -> [MapPoint: Double] {
        var carsPerAddress: [MapPoint: Double] = [:]
        for radius in (1...2) {
            for neighbour in self.mapManager.map.getNeighbourAddresses(to: address, radius: radius) {
                if let tileType = self.mapManager.map.getTile(address: neighbour)?.type {
                    switch tileType {
                    case .building(let size):
                        carsPerAddress[neighbour] = size.double
                    case .cityCouncil:
                        carsPerAddress[neighbour] = 5
                    case .school:
                        carsPerAddress[neighbour] = 5
                    case .hospital:
                        carsPerAddress[neighbour] = 9
                    case .footballPitch(_):
                        carsPerAddress[neighbour] = 5
                    case .warehouse:
                        carsPerAddress[neighbour] = 2
                    default:
                        break
                    }
                }
            }
        }
        return carsPerAddress
    }
    
    func getParkingsAroundAddress(_ address: MapPoint) -> [MapPoint] {
        var parkings: [MapPoint] = []
        for radius in (1...3) {
            for neighbour in self.mapManager.map.getNeighbourAddresses(to: address, radius: radius) {
                if self.mapManager.map.getTile(address: neighbour)?.isParking() ?? false {
                    parkings.append(neighbour)
                }
            }
        }
        return parkings
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

class MontlyIncomePriceList {
    // parking
    public var monthlyParkingIncomePerTakenPlace: Double = 320
}

struct MonthlyIncome {
    let name: String
    let netValue: Double
}
