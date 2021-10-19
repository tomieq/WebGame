//
//  ConstructionServicesTests.swift
//  
//
//  Created by Tomasz Kucharski on 18/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib


final class ConstructionServicesTests: XCTestCase {
    
    func test_roadOfferDuration() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.constructionDuration.road = 10
        
        let offer = constructionServices.roadOffer(landName: "Sample Name")
        XCTAssertEqual(offer.duration, 10)
    }
    
    func test_roadOfferPrice() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.priceList.buildRoadPrice = 10000
        
        let offer = constructionServices.roadOffer(landName: "Sample Name")
        XCTAssertEqual(offer.invoice.netValue, 10000)
    }

    func test_roadOfferTaxRate() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        centralBank.taxRates.investmentTax = 0.5
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.priceList.buildRoadPrice = 10000
        
        let offer = constructionServices.roadOffer(landName: "Sample Name")
        XCTAssertEqual(offer.invoice.netValue, 10000)
        XCTAssertEqual(offer.invoice.tax, 5000)
    }
    
    func test_startRoadInvestment_addressNotFound() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        XCTAssertThrowsError(try constructionServices.startRoadInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .addressNotFound)
        }
    }
    
    func test_startRoadInvestment_playerIsNotTheOwner() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let land = Land(address: MapPoint(x: 0, y: 0))
        dataStore.create(land)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        XCTAssertThrowsError(try constructionServices.startRoadInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .playerIsNotPropertyOwner)
        }
    }
    
    func test_startRoadInvestment_noAccessToRoad() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let land = Land(address: MapPoint(x: 0, y: 0), ownerUUID: "tester")
        dataStore.create(land)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        XCTAssertThrowsError(try constructionServices.startRoadInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .noDirectAccessToRoad)
        }
    }
    
    func test_startRoadInvestment_noEnoughMoney() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "s,s")
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let land = Land(address: MapPoint(x: 0, y: 1), ownerUUID: "p1")
        dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 200)
        dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.priceList.buildRoadPrice = 500

        XCTAssertThrowsError(try constructionServices.startRoadInvestment(address: MapPoint(x: 0, y: 1), playerUUID: "p1")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .financialTransactionProblem(.notEnoughMoney))
        }
    }
    
    func test_startRoadInvestment_success() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "s,s")
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let address = MapPoint(x: 0, y: 1)
        
        let land = Land(address: address, ownerUUID: "p1")
        dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.constructionDuration.road = 5
        constructionServices.priceList.buildRoadPrice = 500

        XCTAssertNoThrow(try constructionServices.startRoadInvestment(address: address, playerUUID: "p1"))
        XCTAssertEqual(map.getTile(address: address)?.type, .streetUnderConstruction)
        let road: Road? = dataStore.find(address: address)
        XCTAssertNotNil(road)
        XCTAssertEqual(road?.isUnderConstruction, true)
        let deletedLand: Land? = dataStore.find(address: address)
        XCTAssertNil(deletedLand)
    }
    
    func test_finishRoadInvestment() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "s,s")
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let address = MapPoint(x: 0, y: 1)
        
        let land = Land(address: address, ownerUUID: "p1")
        dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.constructionDuration.road = 2
        constructionServices.priceList.buildRoadPrice = 500
        
        XCTAssertIdentical(time, constructionServices.currentTime)

        XCTAssertNoThrow(try constructionServices.startRoadInvestment(address: address, playerUUID: "p1"))
        XCTAssertEqual(map.getTile(address: address)?.type, .streetUnderConstruction)
        var road: Road? = dataStore.find(address: address)
        XCTAssertEqual(road?.isUnderConstruction, true)
        XCTAssertEqual(road?.constructionFinishMonth, 2)
        
        // first month
        time.nextMonth()
        constructionServices.finishInvestments()
        road = dataStore.find(address: address)
        XCTAssertEqual(road?.isUnderConstruction, true)
        
        // second month so the investment shoul finish
        time.nextMonth()
        XCTAssertEqual(time.month, 2)
        constructionServices.finishInvestments()
        road = dataStore.find(address: address)
        XCTAssertEqual(road?.isUnderConstruction, false)
    }
    
    func test_residentialBuildingOfferDuration() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.constructionDuration.residentialBuilding = 100
        constructionServices.constructionDuration.residentialBuildingPerStorey = 10
        
        let offer = constructionServices.residentialBuildingOffer(landName: "Test", storeyAmount: 4)
        XCTAssertEqual(offer.duration, 140)
    }
    
    func test_residentialBuildingOfferPrice() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.priceList.buildResidentialBuildingPrice = 10000
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 20
        
        let offer = constructionServices.residentialBuildingOffer(landName: "test", storeyAmount: 3)
        XCTAssertEqual(offer.invoice.netValue, 10060)
    }
    
    func test_residentialBuildingOfferTaxRate() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        centralBank.taxRates.investmentTax = 0.5
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.priceList.buildResidentialBuildingPrice = 10000
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 1000
        
        let offer = constructionServices.residentialBuildingOffer(landName: "test", storeyAmount: 10)
        XCTAssertEqual(offer.invoice.netValue, 20000)
        XCTAssertEqual(offer.invoice.tax, 10000)
    }
    
    func test_startResidentialBuildingInvestment_addressNotFound() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        XCTAssertThrowsError(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "player", storeyAmount: 4)){ error in
            XCTAssertEqual(error as? ConstructionServicesError, .addressNotFound)
        }
    }
    
    func test_startResidentialBuildingInvestment_playerIsNotTheOwner() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let land = Land(address: MapPoint(x: 0, y: 0))
        dataStore.create(land)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        XCTAssertThrowsError(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "player", storeyAmount: 4)){ error in
            XCTAssertEqual(error as? ConstructionServicesError, .playerIsNotPropertyOwner)
        }
    }
    
    func test_startResidentialBuildingInvestment_noAccessToRoad() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let land = Land(address: MapPoint(x: 0, y: 0), ownerUUID: "tester")
        dataStore.create(land)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        XCTAssertThrowsError(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester", storeyAmount: 4)){ error in
            XCTAssertEqual(error as? ConstructionServicesError, .noDirectAccessToRoad)
        }
    }
    
    func test_startResidentialBuildingInvestment_noEnoughMoney() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "s,s")
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let land = Land(address: MapPoint(x: 0, y: 1), ownerUUID: "p1")
        dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 100)
        dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.priceList.buildResidentialBuildingPrice = 500
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 100

        XCTAssertThrowsError(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 1), playerUUID: "p1", storeyAmount: 4)){ error in
            XCTAssertEqual(error as? ConstructionServicesError, .financialTransactionProblem(.notEnoughMoney))
        }
    }
    
    func test_startResidentialBuildingInvestment_success() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "s,s")
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let address = MapPoint(x: 0, y: 1)
        
        let land = Land(address: address, ownerUUID: "p1")
        dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.constructionDuration.residentialBuilding = 5
        constructionServices.constructionDuration.residentialBuildingPerStorey = 1
        constructionServices.priceList.buildResidentialBuildingPrice = 500
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 100

        XCTAssertNoThrow(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 1), playerUUID: "p1", storeyAmount: 4))
        XCTAssertEqual(map.getTile(address: address)?.type, .buildingUnderConstruction(size: 4))
        let building: ResidentialBuilding? = dataStore.find(address: address)
        XCTAssertNotNil(building)
        XCTAssertEqual(building?.isUnderConstruction, true)
        let deletedLand: Land? = dataStore.find(address: address)
        XCTAssertNil(deletedLand)
    }
    
    func test_finishResidentialBuildingInvestment() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        mapManager.loadMapFrom(content: "s,s")
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let address = MapPoint(x: 0, y: 1)
        
        let land = Land(address: address, ownerUUID: "p1")
        dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.constructionDuration.residentialBuilding = 1
        constructionServices.constructionDuration.residentialBuildingPerStorey = 1
        constructionServices.priceList.buildResidentialBuildingPrice = 500
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 100
        
        XCTAssertIdentical(time, constructionServices.currentTime)

        XCTAssertNoThrow(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 1), playerUUID: "p1", storeyAmount: 4))
        XCTAssertEqual(map.getTile(address: address)?.type, .buildingUnderConstruction(size: 4))
        var building: ResidentialBuilding? = dataStore.find(address: address)
        XCTAssertNotNil(building)
        XCTAssertEqual(building?.isUnderConstruction, true)
        XCTAssertEqual(building?.constructionFinishMonth, 5)
        
        // first month
        time.nextMonth()
        constructionServices.finishInvestments()
        building = dataStore.find(address: address)
        XCTAssertEqual(building?.isUnderConstruction, true)
        
        // second month so the investment shoul finish
        time.month = 5
        XCTAssertEqual(time.month, 5)
        constructionServices.finishInvestments()
        building = dataStore.find(address: address)
        XCTAssertEqual(building?.isUnderConstruction, false)
    }
}
