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
        
        agent.syncMapWithDataStore()
        
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
        
        agent.syncMapWithDataStore()
        
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
        
        agent.syncMapWithDataStore()
        
        XCTAssertEqual(map.getTile(address: MapPoint(x: 10, y: 10))?.isBuilding(), true)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 11, y: 11))?.isBuildingUnderConstruction(), true)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 11, y: 11))?.type, .buildingUnderConstruction(size: 6))
    }
    
    func test_initDataStoreResidentialBuildingsFromMap() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "b,B,r,R")
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        
        var building: ResidentialBuilding?
        building = dataStore.find(address: MapPoint(x: 0, y: 0))
        XCTAssertNil(building)
        building = dataStore.find(address: MapPoint(x: 1, y: 0))
        XCTAssertNil(building)
        building = dataStore.find(address: MapPoint(x: 2, y: 0))
        XCTAssertNil(building)
        building = dataStore.find(address: MapPoint(x: 3, y: 0))
        XCTAssertNil(building)
        
        
        agent.syncMapWithDataStore()

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
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "b,B,r,R")
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        
        let building = ResidentialBuilding(land: Land(address: MapPoint(x: 0, y: 0), name: "testing"), storeyAmount: 6)
        let uuid = dataStore.create(building)
        
        agent.syncMapWithDataStore()

        let created: ResidentialBuilding? = dataStore.find(address: MapPoint(x: 0, y: 0))
        XCTAssertEqual(created?.uuid, uuid)
        XCTAssertEqual(created?.name, building.name)
    }
    
    func test_landSaleOffer_notForSale() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        
        let land = Land(address: MapPoint(x: 3, y: 3), ownerUUID: "john")
        dataStore.create(land)
        
        agent.syncMapWithDataStore()
        
        XCTAssertNil(agent.landSaleOffer(address: MapPoint(x: 3, y: 3), buyerUUID: "random"))
    }
    
    func test_landSaleOffer_properOffer() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)

        let offer = agent.landSaleOffer(address: MapPoint(x: 3, y: 3), buyerUUID: "random")
        XCTAssertNotNil(offer)
    }
    
    func test_buyLandProperty_notEnoughMoney() {
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        
        let player = Player(uuid: "buyer", login: "tester", wallet: 100)
        dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        XCTAssertThrowsError(try agent.buyLandProperty(address: MapPoint(x: 3, y: 3), buyerUUID: "buyer")){ error in
            XCTAssertEqual(error as? BuyPropertyError, .financialTransactionProblem(.notEnoughMoney))
        }
    }
    
    func test_buyLandProperty_fromGovernment() {
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.priceList.baseLandValue = 400
        
        let address = MapPoint(x: 3, y: 3)
        let player = Player(uuid: "buyer", login: "tester", wallet: 1000)
        dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: "Agency", wallet: 0)
        dataStore.create(agency)
        
        XCTAssertNoThrow(try agent.buyLandProperty(address: address, buyerUUID: "buyer"))
        
        let land: Land? = dataStore.find(address: address)
        XCTAssertEqual(land?.ownerUUID, "buyer")
    }
    
    func test_residentialBuildingSaleOffer_notABuilding() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)

        XCTAssertNil(agent.residentialBuildingSaleOffer(address: MapPoint(x: 3, y: 3), buyerUUID: "random"))
    }
    
    func test_residentialBuildingSaleOffer_properOffer() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "b")
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        
        agent.syncMapWithDataStore()
        
        XCTAssertNil(agent.landSaleOffer(address: MapPoint(x: 0, y: 0), buyerUUID: "random"))
    }
    
    func test_residentialBuildingSaleOffer_notEnoughMoney() {
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "b")
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.syncMapWithDataStore()
        
        let player = Player(uuid: "buyer", login: "tester", wallet: 0)
        dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        XCTAssertThrowsError(try agent.buyResidentialBuilding(address: MapPoint(x: 0, y: 0), buyerUUID: "buyer")){ error in
            XCTAssertEqual(error as? BuyPropertyError, .financialTransactionProblem(.notEnoughMoney))
        }
    }
    
    func test_residentialBuildingSaleOffer_fromGovernment() {
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "b")
        let agent = RealEstateAgent(mapManager: mapManager, centralBank: centralBank, delegate: nil)
        agent.syncMapWithDataStore()
        let address = MapPoint(x: 0, y: 0)
        let player = Player(uuid: "buyer", login: "tester", wallet: 10000000)
        dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: "Agency", wallet: 0)
        dataStore.create(agency)
        
        XCTAssertNoThrow(try agent.buyResidentialBuilding(address: address, buyerUUID: "buyer"))
        
        let building: ResidentialBuilding? = dataStore.find(address: address)
        XCTAssertEqual(building?.ownerUUID, "buyer")
    }
}
