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
        calculator.monthlyCosts.montlyLandCost = 400
        
        let address = MapPoint(x: 3, y: 3)
        calculator.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        let costs = calculator.getMontlyCosts(address: address)
        let sum = costs.map{$0.price}.reduce(0.0, +)
        XCTAssertEqual(sum, 400)
    }
    
    func test_roadMonthlyCosts() {
        let calculator = self.makeCalculator()
        calculator.monthlyCosts.montlyRoadCost = 800
        
        let address = MapPoint(x: 3, y: 3)
        calculator.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .street(type: .local(.localCross))))
        let costs = calculator.getMontlyCosts(address: address)
        let sum = costs.map{$0.price}.reduce(0.0, +)
        XCTAssertEqual(sum, 800)
    }
    
    func test_residentialBuildingMonthlyCosts() {
        let calculator = self.makeCalculator()
        calculator.monthlyCosts.montlyResidentialBuildingCost = 1000
        calculator.monthlyCosts.montlyResidentialBuildingCostPerStorey = 100
        
        let address = MapPoint(x: 3, y: 3)
        calculator.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .building(size: 6)))
        let costs = calculator.getMontlyCosts(address: address)
        let sum = costs.map{$0.price}.reduce(0.0, +)
        XCTAssertEqual(sum, 1600)
    }
    
    private func makeCalculator() -> PropertyBalanceCalculator {
        
        let map = GameMap(width: 10, height: 10, scale: 0.5)
        let mapManaer = GameMapManager(map)
        let dataStore = DataStoreMemoryProvider()
        let calculator = PropertyBalanceCalculator(mapManager: mapManaer, dataStore: dataStore)
        return calculator
    }
}
