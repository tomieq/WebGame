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
        let router = self.makeRouter()
        router.agent.mapManager.loadMapFrom(content: "s,s")
        
        XCTAssertEqual(router.action(address: MapPoint(x: 0, y: 0), playerUUID: "anybody"), .roadInfo)
    }
    
    func test_openRoadInfoSomebodysRoad() {
        let router = self.makeRouter()
        router.agent.mapManager.loadMapFrom(content: "s,s")
        
        let road = Road(land: Land(address: MapPoint(x: 0, y: 0), ownerUUID: "person1"))
        router.agent.dataStore.create(road)
        
        XCTAssertEqual(router.action(address: MapPoint(x: 0, y: 0), playerUUID: "anybody"), .roadInfo)
    }
    
    func test_openRoadManager() {
        let router = self.makeRouter()
        router.agent.mapManager.loadMapFrom(content: "s,s")
        
        let road = Road(land: Land(address: MapPoint(x: 0, y: 0), ownerUUID: "person1"))
        router.agent.dataStore.create(road)
        
        XCTAssertEqual(router.action(address: MapPoint(x: 0, y: 0), playerUUID: "person1"), .roadManager)
    }
    
    func test_openLandInfo() {
        let router = self.makeRouter()
        router.agent.mapManager.loadMapFrom(content: "s,s")
        
        let address = MapPoint(x: 0, y: 1)
        let land = Land(address: address, ownerUUID: "owner", purchaseNetValue: 900)
        router.agent.dataStore.create(land)
        router.agent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        
        XCTAssertEqual(router.action(address: address, playerUUID: "visitor"), .landInfo)
    }
    
    func test_openLandManager() {
        let router = self.makeRouter()
        router.agent.mapManager.loadMapFrom(content: "s,s")
        
        let address = MapPoint(x: 0, y: 1)
        let land = Land(address: address, ownerUUID: "owner", purchaseNetValue: 900)
        router.agent.dataStore.create(land)
        router.agent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        
        XCTAssertEqual(router.action(address: address, playerUUID: "owner"), .landManager)
    }
    
    func test_openLandSaleOffer() {
        let router = self.makeRouter()
        router.agent.mapManager.loadMapFrom(content: "s,s")
        
        let address = MapPoint(x: 0, y: 1)
        let land = Land(address: address, ownerUUID: "owner", purchaseNetValue: 900)
        router.agent.dataStore.create(land)
        router.agent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        
        XCTAssertNoThrow(try router.agent.registerSaleOffer(address: address, netValue: 1200))
        
        XCTAssertEqual(router.action(address: address, playerUUID: "visitor"), .buyLand)
    }
    
    private func makeRouter() -> ClickTileRouter {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates, time: GameTime())
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let time = GameTime()
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        let propertyValuer = PropertyValuer(mapManager: mapManager, constructionServices: constructionServices)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        let router = ClickTileRouter(agent: agent)
        
        return router
    }
}
