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
        let map = GameMap(width: 10, height: 10, scale: 0.5)
        let mapManaer = GameMapManager(map)
        let dataStore = DataStoreMemoryProvider()
        let calculator = PropertyBalanceCalculator(mapManager: mapManaer, dataStore: dataStore)
        calculator.monthlyCosts.montlyLandCost = 400
        
        let address = MapPoint(x: 3, y: 3)
        map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        
        XCTAssertEqual(calculator.getMontlyCosts(address: address), 400)
    }
    
    func test_roadMonthlyCosts() {
        let map = GameMap(width: 10, height: 10, scale: 0.5)
        let mapManaer = GameMapManager(map)
        let dataStore = DataStoreMemoryProvider()
        let calculator = PropertyBalanceCalculator(mapManager: mapManaer, dataStore: dataStore)
        calculator.monthlyCosts.montlyRoadCost = 800
        
        let address = MapPoint(x: 3, y: 3)
        map.replaceTile(tile: GameMapTile(address: address, type: .street(type: .local(.localCross))))
        
        XCTAssertEqual(calculator.getMontlyCosts(address: address), 800)
    }
    
    func test_residentialBuildingMonthlyCosts() {
        let map = GameMap(width: 10, height: 10, scale: 0.5)
        let mapManaer = GameMapManager(map)
        let dataStore = DataStoreMemoryProvider()
        let calculator = PropertyBalanceCalculator(mapManager: mapManaer, dataStore: dataStore)
        calculator.monthlyCosts.montlyResidentialBuildingCost = 1000
        calculator.monthlyCosts.montlyResidentialBuildingCostPerStorey = 100
        
        let address = MapPoint(x: 3, y: 3)
        map.replaceTile(tile: GameMapTile(address: address, type: .building(size: 6)))
        
        XCTAssertEqual(calculator.getMontlyCosts(address: address), 1600)
    }
}
