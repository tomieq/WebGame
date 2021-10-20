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
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "s,s")
        
        let road = Road(land: Land(address: MapPoint(x: 0, y: 0), ownerUUID: "person1"))
        dataStore.create(road)
        
        let router = ClickTileRouter(map: map, dataStore: dataStore)
        XCTAssertEqual(router.action(address: MapPoint(x: 0, y: 0), playerUUID: "anybody"), .roadInfo)
    }
    
    func test_openRoadManager() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "s,s")
        
        let road = Road(land: Land(address: MapPoint(x: 0, y: 0), ownerUUID: "person1"))
        dataStore.create(road)
        
        let router = ClickTileRouter(map: map, dataStore: dataStore)
        XCTAssertEqual(router.action(address: MapPoint(x: 0, y: 0), playerUUID: "person1"), .roadManager)
    }
}
