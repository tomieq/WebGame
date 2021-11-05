//
//  PropertyBalanceCalculatorTests.swift
//  
//
//  Created by Tomasz Kucharski on 23/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

class PropertyBalanceCalculatorTests: XCTestCase {
    func test_landMonthlyCosts() {
        let calculator = self.makeCalculator()
        calculator.costPriceList.montlyLandWaterCost = 100
        calculator.costPriceList.montlyLandElectricityCost = 300
        calculator.costPriceList.montlyLandMaintenanceCost = 600
        
        let address = MapPoint(x: 3, y: 3)
        calculator.mapManager.addPrivateLand(address: address)
        let costs = calculator.getMontlyCosts(address: address)
        let sum = costs.map{$0.netValue}.reduce(0.0, +)
        XCTAssertEqual(sum, 1000)
    }
    
    func test_roadMonthlyCosts() {
        let calculator = self.makeCalculator()
        calculator.costPriceList.montlyRoadMaintenanceCost = 800
        
        let address = MapPoint(x: 3, y: 3)
        calculator.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .street(type: .local(.localCross))))
        let costs = calculator.getMontlyCosts(address: address)
        let sum = costs.map{$0.netValue}.reduce(0.0, +)
        XCTAssertEqual(sum, 800)
    }
    
    func test_residentialBuildingMonthlyCosts() {
        let calculator = self.makeCalculator()
        calculator.costPriceList.montlyResidentialBuildingWaterCost = 100
        calculator.costPriceList.montlyResidentialBuildingElectricityCost = 300
        calculator.costPriceList.montlyResidentialBuildingMaintenanceCostPerStorey = 1000
        
        let address = MapPoint(x: 3, y: 3)
        calculator.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .building(size: 6)))
        let costs = calculator.getMontlyCosts(address: address)
        let sum = costs.map{$0.netValue}.reduce(0.0, +)
        XCTAssertEqual(sum, 6400)
    }
    
    private func makeCalculator() -> PropertyBalanceCalculator {
        
        let map = GameMap(width: 10, height: 10, scale: 0.5)
        let mapManager = GameMapManager(map)
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let parkingBusiness = ParkingBusiness(mapManager: mapManager, dataStore: dataStore)
        let calculator = PropertyBalanceCalculator(mapManager: mapManager, parkingBusiness: parkingBusiness, taxRates: taxRates)
        return calculator
    }
}
