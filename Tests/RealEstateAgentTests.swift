//
//  RealEstateAgentTests.swift
//  
//
//  Created by Tomasz Kucharski on 16/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class RealEstateAgentTests: XCTestCase {
    
    func test_estimateLocationAtRoad() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 100
        let mapContent = "s,s"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = agent.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 100)
    }
    
    func test_estimateLocationOneTileFromRoad() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 100
        agent.priceList.propertyValueDistanceFromRoadLoss = 0.5
        let mapContent = "s,s"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = agent.estimateValue(MapPoint(x: 0, y: 2))
        XCTAssertEqual(price, 50)
    }
    
    func test_estimateLocationTwoTilesFromRoad() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 100
        agent.priceList.propertyValueDistanceFromRoadLoss = 0.5
        let mapContent = "s,s"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = agent.estimateValue(MapPoint(x: 0, y: 3))
        XCTAssertEqual(price, 25)
    }

    func test_estimateLocationNextToBuilding() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 100
        agent.priceList.propertyValueDistanceFromResidentialBuildingGain = 0.5
        let mapContent = "s,s,B"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = agent.estimateValue(MapPoint(x: 1, y: 1))
        XCTAssertEqual(price, 150)
    }

    func test_estimateLocationNextToTwoBuilding() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 100
        agent.priceList.propertyValueDistanceFromResidentialBuildingGain = 0.5
        let mapContent = "s,s,B\nB"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = agent.estimateValue(MapPoint(x: 1, y: 1))
        XCTAssertEqual(price, 200)
    }
    
    func test_estimateLocationOneTileFromBuilding() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 100
        agent.priceList.propertyValueDistanceFromResidentialBuildingGain = 0.5
        let mapContent = "s,s,B"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = agent.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 125)
    }
}
