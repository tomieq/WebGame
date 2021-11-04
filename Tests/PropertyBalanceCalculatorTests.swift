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
        calculator.priceList.montlyLandWaterCost = 100
        calculator.priceList.montlyLandElectricityCost = 300
        calculator.priceList.montlyLandMaintenanceCost = 600
        
        let address = MapPoint(x: 3, y: 3)
        calculator.mapManager.addPrivateLand(address: address)
        let costs = calculator.getMontlyCosts(address: address)
        let sum = costs.map{$0.netValue}.reduce(0.0, +)
        XCTAssertEqual(sum, 1000)
    }
    
    func test_roadMonthlyCosts() {
        let calculator = self.makeCalculator()
        calculator.priceList.montlyRoadMaintenanceCost = 800
        
        let address = MapPoint(x: 3, y: 3)
        calculator.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .street(type: .local(.localCross))))
        let costs = calculator.getMontlyCosts(address: address)
        let sum = costs.map{$0.netValue}.reduce(0.0, +)
        XCTAssertEqual(sum, 800)
    }
    
    func test_residentialBuildingMonthlyCosts() {
        let calculator = self.makeCalculator()
        calculator.priceList.montlyResidentialBuildingWaterCost = 100
        calculator.priceList.montlyResidentialBuildingElectricityCost = 300
        calculator.priceList.montlyResidentialBuildingMaintenanceCostPerStorey = 1000
        
        let address = MapPoint(x: 3, y: 3)
        calculator.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .building(size: 6)))
        let costs = calculator.getMontlyCosts(address: address)
        let sum = costs.map{$0.netValue}.reduce(0.0, +)
        XCTAssertEqual(sum, 6400)
    }
    
    private func makeCalculator() -> PropertyBalanceCalculator {
        
        let map = GameMap(width: 10, height: 10, scale: 0.5)
        let mapManaer = GameMapManager(map)
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let calculator = PropertyBalanceCalculator(mapManager: mapManaer, dataStore: dataStore, taxRates: taxRates)
        return calculator
    }
}
