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
    
    func test_registerOfferOutsideMap() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)

        XCTAssertThrowsError(try agent.registerSellOffer(address: MapPoint(x: 30, y: 30), netValue: 3000)){ error in
            XCTAssertEqual(error as? RegisterOfferError, .propertyDoesNotExist)
        }
    }
    
    func test_registerOfferOnNonExistingProperty() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        
        XCTAssertThrowsError(try agent.registerSellOffer(address: MapPoint(x: 5, y: 5), netValue: 3000)){ error in
            XCTAssertEqual(error as? RegisterOfferError, .propertyDoesNotExist)
        }
    }
    
    func test_registerLandOffer_verifyExists() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)

        let address = MapPoint(x: 5, y: 5)
        let land = Land(address: address)
        dataStore.create(land)
        map.setTiles([GameMapTile(address: address, type: .soldLand)])
        
        XCTAssertNoThrow(try agent.registerSellOffer(address: address, netValue: 3000))
        //let offer = agent.getOffer(address: address)
        //XCTAssertNotNil(offer)
    }
    
    func test_landSaleOffer_notForSale() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        
        let land = Land(address: MapPoint(x: 3, y: 3), ownerUUID: "john")
        dataStore.create(land)
        
        MapStorageSync(mapManager: mapManager, dataStore: dataStore).syncMapWithDataStore()
        
        XCTAssertNil(agent.landSaleOffer(address: MapPoint(x: 3, y: 3), buyerUUID: "random"))
    }
    
    func test_landSaleOffer_properOffer() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)

        let offer = agent.landSaleOffer(address: MapPoint(x: 3, y: 3), buyerUUID: "random")
        XCTAssertNotNil(offer)
    }
    
    func test_buyLandProperty_notEnoughMoney() {
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        
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
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        propertyValuer.valueFactors.baseLandValue = 400
        
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
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)

        XCTAssertNil(agent.residentialBuildingSaleOffer(address: MapPoint(x: 3, y: 3), buyerUUID: "random"))
    }
    
    func test_residentialBuildingSaleOffer_properOffer() {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "b")
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        
        MapStorageSync(mapManager: mapManager, dataStore: dataStore).syncMapWithDataStore()
        
        XCTAssertNil(agent.landSaleOffer(address: MapPoint(x: 0, y: 0), buyerUUID: "random"))
    }
    
    func test_residentialBuildingSaleOffer_notEnoughMoney() {
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "b")
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        MapStorageSync(mapManager: mapManager, dataStore: dataStore).syncMapWithDataStore()
        
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
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        MapStorageSync(mapManager: mapManager, dataStore: dataStore).syncMapWithDataStore()
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
