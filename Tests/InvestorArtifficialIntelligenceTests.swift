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
        engine.agent.dataStore.update(PlayerMutation(uuid: SystemPlayer.investor.uuid, attributes: [.wallet(90000)]))
        
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
        engine.agent.dataStore.update(PlayerMutation(uuid: SystemPlayer.investor.uuid, attributes: [.wallet(90000)]))
        
        let estimatedValue = engine.agent.propertyValuer.estimateValue(address)
        let offerValue = 1.2 * (estimatedValue ?? 0)
        XCTAssertNoThrow(try engine.agent.registerSaleOffer(address: address, netValue: offerValue))
        
        engine.purchaseBargains()
        
        let soldLand: Land? = engine.agent.dataStore.find(address: address)
        XCTAssertEqual(soldLand?.ownerUUID, "john")
    }
    
    func test_purchaseResidentialBuilding () {
        let engine = self.makeEngine()
        engine.params.instantPurchaseToEstimatedValueFactor = 0.7

        let address = MapPoint(x: 5, y: 5)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "john"), storeyAmount: 6)
        engine.agent.dataStore.create(building)
        engine.agent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .building(size: 6)))
        let owner = Player(uuid: "john", login: "john", wallet: 0)
        engine.agent.dataStore.create(owner)
        engine.params.instantPurchaseToEstimatedValueFactor = 0.85
        
        if let estimatedValue = engine.agent.propertyValuer.estimateValue(address) {
            engine.agent.dataStore.update(PlayerMutation(uuid: SystemPlayer.investor.uuid, attributes: [.wallet(estimatedValue)]))
            let offerValue = 0.8 * estimatedValue
            XCTAssertNoThrow(try engine.agent.registerSaleOffer(address: address, netValue: offerValue))
            
            engine.purchaseBargains()
            
            let building: ResidentialBuilding? = engine.agent.dataStore.find(address: address)
            XCTAssertNotEqual(building?.ownerUUID, "john")
        }
    }
    
    private func makeEngine() -> InvestorArtifficialIntelligence {
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let time = GameTime()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates, time: time)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        let balanceCalculator = PropertyBalanceCalculator(mapManager: mapManager, dataStore: dataStore, taxRates: taxRates)
        let propertyValuer = PropertyValuer(balanceCalculator: balanceCalculator, constructionServices: constructionServices)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: SystemPlayer.government.login, wallet: 0)
        agent.dataStore.create(government)
        
        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: SystemPlayer.realEstateAgency.login, wallet: 0)
        agent.dataStore.create(agency)

        let investor = Player(uuid: SystemPlayer.investor.uuid, login: SystemPlayer.investor.login, wallet: 0)
        agent.dataStore.create(investor)
        
        let engine = InvestorArtifficialIntelligence(agent: agent)
        return engine
    }
}
