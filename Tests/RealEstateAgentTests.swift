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
        let agent = self.makeAgent()

        XCTAssertThrowsError(try agent.registerSaleOffer(address: MapPoint(x: 30, y: 30), netValue: 3000)){ error in
            XCTAssertEqual(error as? RegisterOfferError, .propertyDoesNotExist)
        }
    }
    
    func test_registerOfferOnNonExistingProperty() {
        let agent = self.makeAgent()
        
        XCTAssertThrowsError(try agent.registerSaleOffer(address: MapPoint(x: 5, y: 5), netValue: 3000)){ error in
            XCTAssertEqual(error as? RegisterOfferError, .propertyDoesNotExist)
        }
    }
    
    func test_registerLandOffer_advertExists() {
        let agent = self.makeAgent()

        let address = MapPoint(x: 5, y: 5)
        let land = Land(address: address, ownerUUID: "john")
        agent.dataStore.create(land)
        agent.mapManager.map.setTiles([GameMapTile(address: address, type: .soldLand)])
        
        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 3000))
        let advert: SaleAdvert? = agent.dataStore.find(address: address)
        XCTAssertNotNil(advert)
        XCTAssertEqual(advert?.netPrice, 3000)
    }
    
    func test_registerLandOffer_properOfferNetValue() {
        let agent = self.makeAgent()

        let address = MapPoint(x: 5, y: 5)
        let land = Land(address: address, ownerUUID: "john")
        agent.dataStore.create(land)
        agent.mapManager.map.setTiles([GameMapTile(address: address, type: .soldLand)])
        
        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 3000))
        let offer = agent.landSaleOffer(address: address, buyerUUID: "buyer")
        XCTAssertNotNil(offer)
        XCTAssertEqual(offer?.saleInvoice.netValue, 3000)
    }
    
    func test_landSaleOffer_notForSale() {
        let agent = self.makeAgent()
        
        let land = Land(address: MapPoint(x: 3, y: 3), ownerUUID: "john")
        agent.dataStore.create(land)
        
        MapStorageSync(mapManager: agent.mapManager, dataStore: agent.dataStore).syncMapWithDataStore()
        
        XCTAssertNil(agent.landSaleOffer(address: MapPoint(x: 3, y: 3), buyerUUID: "random"))
    }
    
    func test_landSaleOffer_properOffer() {
        let agent = self.makeAgent()

        let offer = agent.landSaleOffer(address: MapPoint(x: 3, y: 3), buyerUUID: "random")
        XCTAssertNotNil(offer)
    }
    
    func test_buyLandProperty_notEnoughMoney() {
        
        let agent = self.makeAgent()
        
        let player = Player(uuid: "buyer", login: "tester", wallet: 100)
        agent.dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        agent.dataStore.create(government)
        
        XCTAssertThrowsError(try agent.buyLandProperty(address: MapPoint(x: 3, y: 3), buyerUUID: "buyer")){ error in
            XCTAssertEqual(error as? BuyPropertyError, .financialTransactionProblem(.notEnoughMoney))
        }
    }
    
    func test_buyLandProperty_fromGovernment() {
        
        let agent = self.makeAgent()
        agent.propertyValuer.valueFactors.baseLandValue = 400
        
        let address = MapPoint(x: 3, y: 3)
        let player = Player(uuid: "buyer", login: "tester", wallet: 1000)
        agent.dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        agent.dataStore.create(government)
        
        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: "Agency", wallet: 0)
        agent.dataStore.create(agency)
        
        XCTAssertNoThrow(try agent.buyLandProperty(address: address, buyerUUID: "buyer"))
        
        let land: Land? = agent.dataStore.find(address: address)
        XCTAssertEqual(land?.ownerUUID, "buyer")
    }
    
    func test_buyLandProperty_fromOtherUser() {
        
        let agent = self.makeAgent()
        
        let address = MapPoint(x: 3, y: 3)
        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 1000)
        agent.dataStore.create(buyer)
        let land = Land(address: address, ownerUUID: "seller", purchaseNetValue: 100)
        agent.dataStore.create(land)
        agent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        agent.dataStore.create(government)
        
        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: "Agency", wallet: 0)
        agent.dataStore.create(agency)
        
        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 660))
        XCTAssertNoThrow(try agent.buyLandProperty(address: address, buyerUUID: "buyer"))
        
        let soldLand: Land? = agent.dataStore.find(address: address)
        XCTAssertEqual(soldLand?.ownerUUID, "buyer")
        XCTAssertEqual(soldLand?.purchaseNetValue, 660)
    }
    
    func test_buyLandProperty_fromOtherUserIncomeTaxRefund() {
        
        let agent = self.makeAgent()
        agent.centralBank.taxRates.incomeTax = 0.1
        
        let address = MapPoint(x: 3, y: 3)
        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 3000)
        agent.dataStore.create(buyer)
        let land = Land(address: address, ownerUUID: "seller", purchaseNetValue: 600)
        let landID = agent.dataStore.create(land)
        agent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        
        agent.dataStore.update(LandMutation(uuid: landID, attributes: [.investments(400)]))
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        agent.dataStore.create(government)
        
        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: "Agency", wallet: 0)
        agent.dataStore.create(agency)
        
        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 2000))
        XCTAssertNoThrow(try agent.buyLandProperty(address: address, buyerUUID: "buyer"))
        
        let updatedSeller: Player? = agent.dataStore.find(uuid: "seller")
        XCTAssertEqual(updatedSeller?.wallet, 1900)
    }
    
    func test_residentialBuildingSaleOffer_notABuilding() {
        let agent = self.makeAgent()

        XCTAssertNil(agent.residentialBuildingSaleOffer(address: MapPoint(x: 3, y: 3), buyerUUID: "random"))
    }
    
    func test_residentialBuildingSaleOffer_notSorSale() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")

        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "somebody"), storeyAmount: 4)
        agent.dataStore.create(building)
        XCTAssertEqual(agent.mapManager.map.getTile(address: address)?.isBuilding(), true)
        XCTAssertNil(agent.residentialBuildingSaleOffer(address: address, buyerUUID: "random"))
    }
    
    func test_residentialBuildingSaleOffer_properOffer() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")
        
        MapStorageSync(mapManager: agent.mapManager, dataStore: agent.dataStore).syncMapWithDataStore()
        
        XCTAssertNil(agent.landSaleOffer(address: MapPoint(x: 0, y: 0), buyerUUID: "random"))
    }
    
    func test_registerResidentialBuildingOffer_advertExists() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")
        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "seller"), storeyAmount: 4)
        agent.dataStore.create(building)
        
        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 900))
        let advert: SaleAdvert? = agent.dataStore.find(address: address)
        XCTAssertNotNil(advert)
        XCTAssertEqual(advert?.netPrice, 900)
    }
    
    func test_residentialBuildingSaleOffer_notEnoughMoney() {
        
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")
        MapStorageSync(mapManager: agent.mapManager, dataStore: agent.dataStore).syncMapWithDataStore()
        
        let player = Player(uuid: "buyer", login: "tester", wallet: 0)
        agent.dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        agent.dataStore.create(government)
        
        XCTAssertThrowsError(try agent.buyResidentialBuilding(address: MapPoint(x: 0, y: 0), buyerUUID: "buyer")){ error in
            XCTAssertEqual(error as? BuyPropertyError, .financialTransactionProblem(.notEnoughMoney))
        }
    }
    
    func test_residentialBuildingSaleOffer_fromGovernment() {
        
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")
        MapStorageSync(mapManager: agent.mapManager, dataStore: agent.dataStore).syncMapWithDataStore()
        let address = MapPoint(x: 0, y: 0)
        let player = Player(uuid: "buyer", login: "tester", wallet: 10000000)
        agent.dataStore.create(player)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        agent.dataStore.create(government)
        
        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: "Agency", wallet: 0)
        agent.dataStore.create(agency)
        
        XCTAssertNoThrow(try agent.buyResidentialBuilding(address: address, buyerUUID: "buyer"))
        
        let building: ResidentialBuilding? = agent.dataStore.find(address: address)
        XCTAssertEqual(building?.ownerUUID, "buyer")
    }
    
    func test_residentialBuildingSaleOffer_fromOtherUser() {
        
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")
        
        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "seller", purchaseNetValue: 200), storeyAmount: 4)
        agent.dataStore.create(building)
        
        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 100000)
        agent.dataStore.create(buyer)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        agent.dataStore.create(government)
        
        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: "Agency", wallet: 0)
        agent.dataStore.create(agency)
        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 887))
        XCTAssertNoThrow(try agent.buyResidentialBuilding(address: address, buyerUUID: "buyer"))
        
        let soldBuilding: ResidentialBuilding? = agent.dataStore.find(address: address)
        XCTAssertEqual(soldBuilding?.ownerUUID, "buyer")
        XCTAssertEqual(soldBuilding?.purchaseNetValue, 887)
        XCTAssertEqual(soldBuilding?.investmentsNetValue, 0)
    }
    
    private func makeAgent() -> RealEstateAgent {
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let propertyValuer = PropertyValuer(mapManager: mapManager, dataStore: dataStore)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        return agent
    }
}
