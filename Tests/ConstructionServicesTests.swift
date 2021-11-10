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
        
        let constructionServices = self.makeConstructionServices()
        constructionServices.constructionDuration.road = 10
        
        let offer = constructionServices.roadOffer(landName: "Sample Name")
        XCTAssertEqual(offer.duration, 10)
    }
    
    func test_roadOfferPrice() {
        let constructionServices = self.makeConstructionServices()
        constructionServices.priceList.buildRoadPrice = 10000
        
        let offer = constructionServices.roadOffer(landName: "Sample Name")
        XCTAssertEqual(offer.invoice.netValue, 10000)
    }

    func test_roadOfferTaxRate() {
        let constructionServices = self.makeConstructionServices()
        constructionServices.priceList.buildRoadPrice = 10000
        constructionServices.centralBank.taxRates.investmentTax = 0.5
        
        let offer = constructionServices.roadOffer(landName: "Sample Name")
        XCTAssertEqual(offer.invoice.netValue, 10000)
        XCTAssertEqual(offer.invoice.tax, 5000)
    }
    
    func test_startRoadInvestment_addressNotFound() {
        let constructionServices = self.makeConstructionServices()
        XCTAssertThrowsError(try constructionServices.startRoadInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .addressNotFound)
        }
    }
    
    func test_startRoadInvestment_playerIsNotTheOwner() {
        
        let constructionServices = self.makeConstructionServices()
        
        let land = Land(address: MapPoint(x: 0, y: 0))
        constructionServices.dataStore.create(land)
        
        XCTAssertThrowsError(try constructionServices.startRoadInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .playerIsNotPropertyOwner)
        }
    }
    
    func test_startRoadInvestment_noAccessToRoad() {
        
        let constructionServices = self.makeConstructionServices()
        
        let land = Land(address: MapPoint(x: 0, y: 0), ownerUUID: "tester")
        constructionServices.dataStore.create(land)
        
        XCTAssertThrowsError(try constructionServices.startRoadInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .noDirectAccessToRoad)
        }
    }
    
    func test_startRoadInvestment_noEnoughMoney() {
        
        let constructionServices = self.makeConstructionServices()
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        let land = Land(address: MapPoint(x: 0, y: 1), ownerUUID: "p1")
        constructionServices.dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 200)
        constructionServices.dataStore.create(player)
        
        constructionServices.priceList.buildRoadPrice = 500

        XCTAssertThrowsError(try constructionServices.startRoadInvestment(address: MapPoint(x: 0, y: 1), playerUUID: "p1")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .financialTransactionProblem(.notEnoughMoney))
        }
    }
    
    func test_startRoadInvestment_success() {
        let constructionServices = self.makeConstructionServices()
        
        let dataStore = constructionServices.dataStore
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        
        let address = MapPoint(x: 0, y: 1)
        
        let land = Land(address: address, ownerUUID: "p1")
        let uuid = dataStore.create(land)
        dataStore.create(PropertyRegister(uuid: uuid, address: address, playerUUID: "p1", type: .land))
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        dataStore.create(player)
        
        constructionServices.constructionDuration.road = 5
        constructionServices.priceList.buildRoadPrice = 500

        XCTAssertNoThrow(try constructionServices.startRoadInvestment(address: address, playerUUID: "p1"))
        XCTAssertEqual(constructionServices.mapManager.map.getTile(address: address)?.type, .streetUnderConstruction)
        let road: Road? = dataStore.find(address: address)
        XCTAssertNotNil(road)
        XCTAssertEqual(road?.isUnderConstruction, true)
        let deletedLand: Land? = dataStore.find(address: address)
        XCTAssertNil(deletedLand)
        let register: PropertyRegister? = dataStore.find(uuid: uuid)
        XCTAssertEqual(register?.type, .road)
    }
    
    func test_startRoadInvestment_verifyInvestmentValue() {

        let constructionServices = self.makeConstructionServices()
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        
        let address = MapPoint(x: 0, y: 1)
        
        let land = Land(address: address, ownerUUID: "p1")
        constructionServices.dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        constructionServices.dataStore.create(player)

        constructionServices.priceList.buildRoadPrice = 500

        XCTAssertNoThrow(try constructionServices.startRoadInvestment(address: address, playerUUID: "p1"))
        XCTAssertEqual(constructionServices.mapManager.map.getTile(address: address)?.type, .streetUnderConstruction)
        let road: Road? = constructionServices.dataStore.find(address: address)
        XCTAssertNotNil(road)
        XCTAssertEqual(road?.investmentsNetValue, 500)
    }
    
    func test_finishRoadInvestment() {
        
        let constructionServices = self.makeConstructionServices()
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        
        let address = MapPoint(x: 0, y: 1)
        
        let land = Land(address: address, ownerUUID: "p1")
        constructionServices.dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        constructionServices.dataStore.create(player)

        constructionServices.constructionDuration.road = 2
        constructionServices.priceList.buildRoadPrice = 500
        
        XCTAssertIdentical(constructionServices.time, constructionServices.time)

        XCTAssertNoThrow(try constructionServices.startRoadInvestment(address: address, playerUUID: "p1"))
        XCTAssertEqual(constructionServices.mapManager.map.getTile(address: address)?.type, .streetUnderConstruction)
        var road: Road? = constructionServices.dataStore.find(address: address)
        XCTAssertEqual(road?.isUnderConstruction, true)
        XCTAssertEqual(road?.constructionFinishMonth, 2)
        
        // first month
        constructionServices.time.nextMonth()
        constructionServices.finishInvestments()
        road = constructionServices.dataStore.find(address: address)
        XCTAssertEqual(road?.isUnderConstruction, true)
        
        // second month so the investment shoul finish
        constructionServices.time.nextMonth()
        XCTAssertEqual(constructionServices.time.month, 2)
        constructionServices.finishInvestments()
        road = constructionServices.dataStore.find(address: address)
        XCTAssertEqual(road?.isUnderConstruction, false)
    }
    
    func test_residentialBuildingOfferDuration() {
        let constructionServices = self.makeConstructionServices()
        constructionServices.constructionDuration.residentialBuilding = 100
        constructionServices.constructionDuration.residentialBuildingPerStorey = 10
        
        let offer = constructionServices.residentialBuildingOffer(landName: "Test", storeyAmount: 4)
        XCTAssertEqual(offer.duration, 140)
    }
    
    func test_residentialBuildingOfferPrice() {
        let constructionServices = self.makeConstructionServices()
        constructionServices.priceList.buildResidentialBuildingPrice = 10000
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 20
        
        let offer = constructionServices.residentialBuildingOffer(landName: "test", storeyAmount: 3)
        XCTAssertEqual(offer.invoice.netValue, 10060)
    }
    
    func test_residentialBuildingOfferTaxRate() {
        let constructionServices = self.makeConstructionServices()
        constructionServices.centralBank.taxRates.investmentTax = 0.5
        
        constructionServices.priceList.buildResidentialBuildingPrice = 10000
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 1000
        
        let offer = constructionServices.residentialBuildingOffer(landName: "test", storeyAmount: 10)
        XCTAssertEqual(offer.invoice.netValue, 20000)
        XCTAssertEqual(offer.invoice.tax, 10000)
    }
    
    func test_startResidentialBuildingInvestment_addressNotFound() {
        let constructionServices = self.makeConstructionServices()
        XCTAssertThrowsError(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "player", storeyAmount: 4)){ error in
            XCTAssertEqual(error as? ConstructionServicesError, .addressNotFound)
        }
    }
    
    func test_startResidentialBuildingInvestment_playerIsNotTheOwner() {
        let constructionServices = self.makeConstructionServices()
        
        let land = Land(address: MapPoint(x: 0, y: 0))
        constructionServices.dataStore.create(land)
        
        XCTAssertThrowsError(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "player", storeyAmount: 4)){ error in
            XCTAssertEqual(error as? ConstructionServicesError, .playerIsNotPropertyOwner)
        }
    }
    
    func test_startResidentialBuildingInvestment_noAccessToRoad() {
        let constructionServices = self.makeConstructionServices()
        
        let land = Land(address: MapPoint(x: 0, y: 0), ownerUUID: "tester")
        constructionServices.dataStore.create(land)
        
        XCTAssertThrowsError(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester", storeyAmount: 4)){ error in
            XCTAssertEqual(error as? ConstructionServicesError, .noDirectAccessToRoad)
        }
    }
    
    func test_startResidentialBuildingInvestment_noEnoughMoney() {
        
        let constructionServices = self.makeConstructionServices()
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        
        let land = Land(address: MapPoint(x: 0, y: 1), ownerUUID: "p1")
        constructionServices.dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 100)
        constructionServices.dataStore.create(player)
        
        constructionServices.priceList.buildResidentialBuildingPrice = 500
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 100

        XCTAssertThrowsError(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 1), playerUUID: "p1", storeyAmount: 4)){ error in
            XCTAssertEqual(error as? ConstructionServicesError, .financialTransactionProblem(.notEnoughMoney))
        }
    }
    
    func test_startResidentialBuildingInvestment_success() {
        
        let constructionServices = self.makeConstructionServices()
        let dataStore = constructionServices.dataStore
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        let address = MapPoint(x: 0, y: 1)
        
        let land = Land(address: address, ownerUUID: "p1")
        let uuid = dataStore.create(land)
        dataStore.create(PropertyRegister(uuid: uuid, address: address, playerUUID: "p1", type: .land))
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        constructionServices.dataStore.create(player)
        
        constructionServices.constructionDuration.residentialBuilding = 5
        constructionServices.constructionDuration.residentialBuildingPerStorey = 1
        constructionServices.priceList.buildResidentialBuildingPrice = 500
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 100

        XCTAssertNoThrow(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 1), playerUUID: "p1", storeyAmount: 4))
        XCTAssertEqual(constructionServices.mapManager.map.getTile(address: address)?.type, .buildingUnderConstruction(size: 4))
        let building: ResidentialBuilding? = dataStore.find(address: address)
        XCTAssertNotNil(building)
        XCTAssertEqual(building?.isUnderConstruction, true)
        let deletedLand: Land? = dataStore.find(address: address)
        XCTAssertNil(deletedLand)
        let register: PropertyRegister? = dataStore.find(uuid: uuid)
        XCTAssertEqual(register?.type, .residentialBuilding)
    }
    
    func test_startResidentialBuildingInvestment_verifyInvestmentValue() {
        
        let constructionServices = self.makeConstructionServices()
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        
        let address = MapPoint(x: 0, y: 1)
        
        let land = Land(address: address, ownerUUID: "p1")
        constructionServices.dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        constructionServices.dataStore.create(player)
        
        constructionServices.priceList.buildResidentialBuildingPrice = 500
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 100

        XCTAssertNoThrow(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 1), playerUUID: "p1", storeyAmount: 4))
        XCTAssertEqual(constructionServices.mapManager.map.getTile(address: address)?.type, .buildingUnderConstruction(size: 4))
        let building: ResidentialBuilding? = constructionServices.dataStore.find(address: address)
        XCTAssertNotNil(building)
        XCTAssertEqual(building?.investmentsNetValue, 900)
    }
    
    func test_finishResidentialBuildingInvestment() {
        
        let constructionServices = self.makeConstructionServices()
        let dataStore = constructionServices.dataStore
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        let address = MapPoint(x: 0, y: 1)
        
        let land = Land(address: address, ownerUUID: "p1")
        dataStore.create(land)
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        dataStore.create(player)
        
        constructionServices.constructionDuration.residentialBuilding = 1
        constructionServices.constructionDuration.residentialBuildingPerStorey = 1
        constructionServices.priceList.buildResidentialBuildingPrice = 500
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 100
        
        XCTAssertIdentical(constructionServices.time, constructionServices.time)

        XCTAssertNoThrow(try constructionServices.startResidentialBuildingInvestment(address: MapPoint(x: 0, y: 1), playerUUID: "p1", storeyAmount: 4))
        XCTAssertEqual(constructionServices.mapManager.map.getTile(address: address)?.type, .buildingUnderConstruction(size: 4))
        var building: ResidentialBuilding? = constructionServices.dataStore.find(address: address)
        XCTAssertNotNil(building)
        XCTAssertEqual(building?.isUnderConstruction, true)
        XCTAssertEqual(building?.constructionFinishMonth, 5)
        
        // first month
        constructionServices.time.nextMonth()
        constructionServices.finishInvestments()
        building = dataStore.find(address: address)
        XCTAssertEqual(building?.isUnderConstruction, true)
        
        // second month so the investment should finish
        constructionServices.time.month = 5
        XCTAssertEqual(constructionServices.time.month, 5)
        constructionServices.finishInvestments()
        building = dataStore.find(address: address)
        XCTAssertEqual(building?.isUnderConstruction, false)
        
        let apartments: [Apartment] = dataStore.get(address: address)
        XCTAssertEqual(apartments.count, building?.numberOfFlats)
    }

    func test_startParkingInvestment_addressNotFound() {
        let constructionServices = self.makeConstructionServices()
        XCTAssertThrowsError(try constructionServices.startParkingInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .addressNotFound)
        }
    }
    
    func test_startParkingInvestment_playerIsNotTheOwner() {
        
        let constructionServices = self.makeConstructionServices()
        let dataStore = constructionServices.dataStore
        dataStore.create(Land(address: MapPoint(x: 0, y: 0), ownerUUID: "otherUser"))
        
        XCTAssertThrowsError(try constructionServices.startParkingInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .playerIsNotPropertyOwner)
        }
    }
    
    func test_startParkingInvestment_noAccessToRoad() {
        
        let constructionServices = self.makeConstructionServices()
        let dataStore = constructionServices.dataStore
        dataStore.create(Land(address: MapPoint(x: 0, y: 0), ownerUUID: "tester"))
        
        XCTAssertThrowsError(try constructionServices.startParkingInvestment(address: MapPoint(x: 0, y: 0), playerUUID: "tester")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .noDirectAccessToRoad)
        }
    }

    func test_startParkingInvestment_noEnoughMoney() {
        
        let constructionServices = self.makeConstructionServices()
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        let dataStore = constructionServices.dataStore
        let address = MapPoint(x: 1, y: 1)
        dataStore.create(Land(address: address, ownerUUID: "p1"))
        
        let player = Player(uuid: "p1", login: "tester", wallet: 200)
        dataStore.create(player)
        
        constructionServices.priceList.buildParkingPrice = 500

        XCTAssertThrowsError(try constructionServices.startParkingInvestment(address: address, playerUUID: "p1")){ error in
            XCTAssertEqual(error as! ConstructionServicesError, .financialTransactionProblem(.notEnoughMoney))
        }
    }
    
    func test_startParkingInvestment_success() {
        let constructionServices = self.makeConstructionServices()
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        let dataStore = constructionServices.dataStore
        let address = MapPoint(x: 0, y: 1)
        
        let uuid = dataStore.create(Land(address: address, ownerUUID: "p1"))
        dataStore.create(PropertyRegister(uuid: uuid, address: address, playerUUID: "p1", type: .land))
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        dataStore.create(player)
        
        constructionServices.constructionDuration.parking = 5
        constructionServices.priceList.buildParkingPrice = 500

        XCTAssertNoThrow(try constructionServices.startParkingInvestment(address: address, playerUUID: "p1"))
        XCTAssertEqual(constructionServices.mapManager.map.getTile(address: address)?.type, .parkingUnderConstruction)
        let parking: Parking? = constructionServices.dataStore.find(address: address)
        XCTAssertNotNil(parking)
        XCTAssertEqual(parking?.isUnderConstruction, true)
        let deletedLand: Land? = constructionServices.dataStore.find(address: address)
        XCTAssertNil(deletedLand)
        let register: PropertyRegister? = dataStore.find(uuid: uuid)
        XCTAssertEqual(register?.type, .parking)
    }
    
    func test_finishParkingInvestment() {
        
        let constructionServices = self.makeConstructionServices()
        constructionServices.mapManager.loadMapFrom(content: "s,s")
        
        let dataStore = constructionServices.dataStore
        let address = MapPoint(x: 0, y: 1)

        constructionServices.dataStore.create(Land(address: address, ownerUUID: "p1"))
        
        let player = Player(uuid: "p1", login: "tester", wallet: 1200)
        dataStore.create(player)

        constructionServices.constructionDuration.parking = 2
        constructionServices.priceList.buildParkingPrice = 500
        
        XCTAssertIdentical(constructionServices.time, constructionServices.time)

        XCTAssertNoThrow(try constructionServices.startParkingInvestment(address: address, playerUUID: "p1"))
        XCTAssertEqual(constructionServices.mapManager.map.getTile(address: address)?.type, .parkingUnderConstruction)
        var parking: Parking? = constructionServices.dataStore.find(address: address)
        XCTAssertEqual(parking?.isUnderConstruction, true)
        XCTAssertEqual(parking?.constructionFinishMonth, 2)
        
        // first month
        constructionServices.time.nextMonth()
        constructionServices.finishInvestments()
        parking = constructionServices.dataStore.find(address: address)
        XCTAssertEqual(parking?.isUnderConstruction, true)
        
        // second month so the investment shoul finish
        constructionServices.time.nextMonth()
        XCTAssertEqual(constructionServices.time.month, 2)
        constructionServices.finishInvestments()
        parking = constructionServices.dataStore.find(address: address)
        XCTAssertEqual(parking?.isUnderConstruction, false)
        XCTAssertEqual(constructionServices.mapManager.map.getTile(address: address)?.type, .parking(type: .topConnection))
    }
    
    private func makeConstructionServices() -> ConstructionServices {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates, time: time)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        dataStore.create(government)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        return constructionServices
    }
    
}
