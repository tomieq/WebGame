//
//  GovernmentEngineTests.swift
//  
//
//  Created by Tomasz Kucharski on 22/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib


final class InvestorArtifficialIntelligenceTests: XCTestCase {

    func test_purchaseBargains_oneCheapSaleOffer () {
        let engine = self.makeEngine()
        engine.params.instantPurchaseToEstimatedValueFactor = 0.7

        let address = MapPoint(x: 5, y: 5)
        let land = Land(address: address, ownerUUID: "john")
        engine.agent.dataStore.create(land)
        engine.agent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        let owner = Player(uuid: "john", login: "john", wallet: 0)
        engine.agent.dataStore.create(owner)
        engine.agent.dataStore.update(PlayerMutation(id: SystemPlayer.government.uuid, attributes: [.wallet(90000)]))
        
        let estimatedValue = engine.agent.propertyValuer.estimateValue(address)
        let offerValue = 0.6 * (estimatedValue ?? 0)
        XCTAssertNoThrow(try engine.agent.registerSaleOffer(address: address, netValue: offerValue))
        
        engine.purchaseBargains()
        
        let soldLand: Land? = engine.agent.dataStore.find(address: address)
        XCTAssertNotEqual(soldLand?.ownerUUID, "john")
    }
    
    func test_purchaseBargains_oneExpensiveSaleOffer () {
        let engine = self.makeEngine()
        engine.params.instantPurchaseToEstimatedValueFactor = 0.7

        let address = MapPoint(x: 5, y: 5)
        let land = Land(address: address, ownerUUID: "john")
        engine.agent.dataStore.create(land)
        engine.agent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        let owner = Player(uuid: "john", login: "john", wallet: 0)
        engine.agent.dataStore.create(owner)
        engine.agent.dataStore.update(PlayerMutation(id: SystemPlayer.government.uuid, attributes: [.wallet(90000)]))
        
        let estimatedValue = engine.agent.propertyValuer.estimateValue(address)
        let offerValue = 1.2 * (estimatedValue ?? 0)
        XCTAssertNoThrow(try engine.agent.registerSaleOffer(address: address, netValue: offerValue))
        
        engine.purchaseBargains()
        
        let soldLand: Land? = engine.agent.dataStore.find(address: address)
        XCTAssertEqual(soldLand?.ownerUUID, "john")
    }
    
    private func makeEngine() -> InvestorArtifficialIntelligence {
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let time = GameTime()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates, time: time)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        let propertyValuer = PropertyValuer(mapManager: mapManager, constructionServices: constructionServices)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: "Big Uncle", wallet: 0)
        agent.dataStore.create(government)
        
        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: "Agency", wallet: 0)
        agent.dataStore.create(agency)
        
        let engine = InvestorArtifficialIntelligence(agent: agent)
        return engine
    }
}
