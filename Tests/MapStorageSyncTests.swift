//
//  MapStorageSyncTests.swift
//  
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib


final class MapStorageSyncTests: XCTestCase {
    
    func test_initMapRoadsFromDataStore() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let sync = MapStorageSync(mapManager: mapManager, dataStore: dataStore)
        
        XCTAssertNil(map.getTile(address: MapPoint(x: 20, y: 20)))
        XCTAssertNil(map.getTile(address: MapPoint(x: 21, y: 20)))
        XCTAssertNil(map.getTile(address: MapPoint(x: 22, y: 20)))
        
        let road1 = Road(land: Land(address: MapPoint(x: 20, y: 20)))
        let road2 = Road(land: Land(address: MapPoint(x: 21, y: 20)))
        dataStore.create(road1)
        dataStore.create(road2)
        
        let roadUnderConstruction = Road(land: Land(address: MapPoint(x: 22, y: 20)), constructionFinishMonth: 2)
        dataStore.create(roadUnderConstruction)
        
        sync.syncMapWithDataStore()
        
        XCTAssertEqual(map.getTile(address: MapPoint(x: 20, y: 20))?.isStreet(), true)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 21, y: 20))?.isStreet(), true)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 22, y: 20))?.isStreetUnderConstruction(), true)
    }
    
    func test_initMapSoldLandsFromDataStore() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let sync = MapStorageSync(mapManager: mapManager, dataStore: dataStore)
        
        XCTAssertNil(map.getTile(address: MapPoint(x: 10, y: 10)))
        
        let land = Land(address: MapPoint(x: 10, y: 10))
        dataStore.create(land)
        
        sync.syncMapWithDataStore()
        
        XCTAssertEqual(map.getTile(address: MapPoint(x: 10, y: 10))?.type, .soldLand)
    }
    
    func test_initMapResidentialBuildingsFromDataStore() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let sync = MapStorageSync(mapManager: mapManager, dataStore: dataStore)
        
        XCTAssertNil(map.getTile(address: MapPoint(x: 10, y: 10)))
        XCTAssertNil(map.getTile(address: MapPoint(x: 11, y: 11)))
        
        let building = ResidentialBuilding(land: Land(address: MapPoint(x: 10, y: 10)), storeyAmount: 6)
        dataStore.create(building)
        let buildingUnderConstruction = ResidentialBuilding(land: Land(address: MapPoint(x: 11, y: 11)), storeyAmount: 6, constructionFinishMonth: 5)
        dataStore.create(buildingUnderConstruction)
        
        sync.syncMapWithDataStore()
        
        XCTAssertEqual(map.getTile(address: MapPoint(x: 10, y: 10))?.isBuilding(), true)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 11, y: 11))?.isBuildingUnderConstruction(), true)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 11, y: 11))?.type, .buildingUnderConstruction(size: 6))
    }
    
    func test_initDataStoreResidentialBuildingsFromMap() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "b,B,r,R")
        let sync = MapStorageSync(mapManager: mapManager, dataStore: dataStore)
        
        var building: ResidentialBuilding?
        building = dataStore.find(address: MapPoint(x: 0, y: 0))
        XCTAssertNil(building)
        building = dataStore.find(address: MapPoint(x: 1, y: 0))
        XCTAssertNil(building)
        building = dataStore.find(address: MapPoint(x: 2, y: 0))
        XCTAssertNil(building)
        building = dataStore.find(address: MapPoint(x: 3, y: 0))
        XCTAssertNil(building)
        
        
        sync.syncMapWithDataStore()

        building = dataStore.find(address: MapPoint(x: 0, y: 0))
        XCTAssertEqual(building?.storeyAmount, 4)
        XCTAssertEqual(building?.ownerUUID, SystemPlayer.government.uuid)
        building = dataStore.find(address: MapPoint(x: 1, y: 0))
        XCTAssertEqual(building?.storeyAmount, 6)
        building = dataStore.find(address: MapPoint(x: 2, y: 0))
        XCTAssertEqual(building?.storeyAmount, 8)
        building = dataStore.find(address: MapPoint(x: 3, y: 0))
        XCTAssertEqual(building?.storeyAmount, 10)
    }
    
    func test_initDataStoreResidentialBuildingsFromMap_doNotReplaceExisting() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "b,B,r,R")
        let sync = MapStorageSync(mapManager: mapManager, dataStore: dataStore)
        
        let building = ResidentialBuilding(land: Land(address: MapPoint(x: 0, y: 0), name: "testing"), storeyAmount: 6)
        let uuid = dataStore.create(building)
        
        sync.syncMapWithDataStore()

        let created: ResidentialBuilding? = dataStore.find(address: MapPoint(x: 0, y: 0))
        XCTAssertEqual(created?.uuid, uuid)
        XCTAssertEqual(created?.name, building.name)
    }
}
