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
    
    func test_estimateLandValueAtRoad() {
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
    
    func test_estimateLandValueOneTileFromRoad() {
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
    
    func test_estimateLandValueTwoTilesFromRoad() {
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

    func test_estimateLandValueNextToBuilding() {
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

    func test_estimateLandValueNextToTwoBuildings() {
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
    
    func test_estimateLandValueTwoTilesFromBuilding() {
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
    
    func test_estimateLandValueOneTileFromAntenna() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 100
        agent.priceList.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,A"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = agent.estimateValue(MapPoint(x: 1, y: 1))
        XCTAssertEqual(price, 20)
    }
    
    func test_estimateLandValueTwoTilesFromAntenna() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 100
        agent.priceList.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,A"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = agent.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 40)
    }
    
    func test_estimateLandValueThreeTilesFromAntenna() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 100
        agent.priceList.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,s,A"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = agent.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 60)
    }
    
    func test_estimateLandValueFourTilesFromAntenna() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 100
        agent.priceList.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,s,s,A"
        mapManager.loadMapFrom(content: mapContent)
        
        let price = agent.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 100)
    }
    
    func test_initMapRoadsFromDataStore() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        
        XCTAssertNil(map.getTile(address: MapPoint(x: 20, y: 20)))
        XCTAssertNil(map.getTile(address: MapPoint(x: 21, y: 20)))
        XCTAssertNil(map.getTile(address: MapPoint(x: 22, y: 20)))
        
        let road1 = Road(land: Land(address: MapPoint(x: 20, y: 20)))
        let road2 = Road(land: Land(address: MapPoint(x: 21, y: 20)))
        dataStore.create(road1)
        dataStore.create(road2)
        
        let roadUnderConstruction = Road(land: Land(address: MapPoint(x: 22, y: 20)), constructionFinishMonth: 2)
        dataStore.create(roadUnderConstruction)
        
        agent.makeMapTilesFromDataStore()
        
        XCTAssertEqual(map.getTile(address: MapPoint(x: 20, y: 20))?.isStreet(), true)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 21, y: 20))?.isStreet(), true)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 22, y: 20))?.isStreetUnderConstruction(), true)
    }
    
    func test_initMapSoldLandsFromDataStore() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        
        XCTAssertNil(map.getTile(address: MapPoint(x: 10, y: 10)))
        
        let land = Land(address: MapPoint(x: 10, y: 10))
        dataStore.create(land)
        
        agent.makeMapTilesFromDataStore()
        
        XCTAssertEqual(map.getTile(address: MapPoint(x: 10, y: 10))?.type, .soldLand)
    }
    
    func test_initMapResidentialBuildingsFromDataStore() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        
        XCTAssertNil(map.getTile(address: MapPoint(x: 10, y: 10)))
        XCTAssertNil(map.getTile(address: MapPoint(x: 11, y: 11)))
        
        let building = ResidentialBuilding(land: Land(address: MapPoint(x: 10, y: 10)), storeyAmount: 6)
        dataStore.create(building)
        let buildingUnderConstruction = ResidentialBuilding(land: Land(address: MapPoint(x: 11, y: 11)), storeyAmount: 6, constructionFinishMonth: 5)
        dataStore.create(buildingUnderConstruction)
        
        agent.makeMapTilesFromDataStore()
        
        XCTAssertEqual(map.getTile(address: MapPoint(x: 10, y: 10))?.isBuilding(), true)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 11, y: 11))?.isBuilding(), true)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 11, y: 11))?.type, .buildingUnderConstruction(size: 6))
    }
}
