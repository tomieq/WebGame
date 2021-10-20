//
//  ClickTileRouterTests.swift
//  
//
//  Created by Tomasz Kucharski on 20/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib


final class ClickTileRouterTests: XCTestCase {
    
    func test_openRoadInfoUnownedRoad() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "s,s")
        let dataStore = DataStoreMemoryProvider()
        
        let router = ClickTileRouter(map: map, dataStore: dataStore)
        
        XCTAssertEqual(router.action(address: MapPoint(x: 0, y: 0), playerUUID: "anybody"), .roadInfo)
    }
    
    func test_openRoadInfoSomebodysRoad() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        
        let road1 = Road(land: Land(address: MapPoint(x: 20, y: 20), ownerUUID: "person1"))
        let road2 = Road(land: Land(address: MapPoint(x: 21, y: 20)))
        dataStore.create(road1)
        dataStore.create(road2)
        
        agent.syncMapWithDataStore()
        let router = ClickTileRouter(map: map, dataStore: dataStore)
        XCTAssertEqual(router.action(address: MapPoint(x: 20, y: 20), playerUUID: "anybody"), .roadInfo)
    }
    
    func test_openRoadManager() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        
        let road1 = Road(land: Land(address: MapPoint(x: 20, y: 20), ownerUUID: "person1"))
        let road2 = Road(land: Land(address: MapPoint(x: 21, y: 20)))
        dataStore.create(road1)
        dataStore.create(road2)
        
        agent.syncMapWithDataStore()
        let router = ClickTileRouter(map: map, dataStore: dataStore)
        XCTAssertEqual(router.action(address: MapPoint(x: 20, y: 20), playerUUID: "person1"), .roadManager)
    }
}
