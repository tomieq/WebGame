//
//  PropertyValuerTests.swift
//  
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class PropertyValuerTests: XCTestCase {
    
    func test_estimateLandValueAtRoad() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let valuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        valuer.valueFactors.baseLandValue = 100
        let mapContent = "s,s"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 100)
    }
    
    func test_estimateLandValueOneTileFromRoad() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let valuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueDistanceFromRoadLoss = 0.5
        let mapContent = "s,s"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 2))
        XCTAssertEqual(price, 50)
    }
    
    func test_estimateLandValueTwoTilesFromRoad() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let valuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueDistanceFromRoadLoss = 0.5
        let mapContent = "s,s"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 3))
        XCTAssertEqual(price, 25)
    }

    func test_estimateLandValueNextToBuilding() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let valuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueDistanceFromResidentialBuildingGain = 0.5
        let mapContent = "s,s,B"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 1, y: 1))
        XCTAssertEqual(price, 150)
    }

    func test_estimateLandValueNextToTwoBuildings() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let valuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueDistanceFromResidentialBuildingGain = 0.5
        let mapContent = "s,s,B\nB"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 1, y: 1))
        XCTAssertEqual(price, 200)
    }
    
    func test_estimateLandValueTwoTilesFromBuilding() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let valuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueDistanceFromResidentialBuildingGain = 0.5
        let mapContent = "s,s,B"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 125)
    }
    
    func test_estimateLandValueOneTileFromAntenna() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let valuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,A"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 1, y: 1))
        XCTAssertEqual(price, 20)
    }
    
    func test_estimateLandValueTwoTilesFromAntenna() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let valuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,A"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 40)
    }
    
    func test_estimateLandValueThreeTilesFromAntenna() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let valuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,s,A"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 60)
    }
    
    func test_estimateLandValueFourTilesFromAntenna() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let valuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,s,s,A"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 100)
    }
}
