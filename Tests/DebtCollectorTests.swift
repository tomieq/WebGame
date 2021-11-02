//
//  DebtCollectorTests.swift
//  
//
//  Created by Tomasz Kucharski on 02/11/2021.
//

import Foundation
import XCTest
@testable import WebGameLib


class DebtCollectorTests: XCTestCase {
    
    func test_fishPlayersWithDebts() {
        let collector = self.makeDebtCollector()
        let dataStore = collector.dataStore
        
        let player2 = Player(uuid: "player2", login: "Player2", wallet: 50000)
        dataStore.create(player2)
        
        collector.executeDebts()
        XCTAssertTrue(collector.isExecuted(playerUUID: "player"))
        XCTAssertFalse(collector.isExecuted(playerUUID: "player2"))
    }
    
    func test_notificationAboutDebts() {
        let collector = self.makeDebtCollector()
        let delegate = DebtCollectorTestDelegate()
        collector.delegate = delegate
        let time = collector.time
        
        XCTAssertEqual(delegate.notifuUUID.count, 0)
        collector.executeDebts()
        XCTAssertEqual(delegate.notifuUUID.count, 0)
        time.nextMonth()
        collector.executeDebts()
        XCTAssertEqual(delegate.notifuUUID.count, 1)
    }
    
    func test_propertyRegisterStatusChanged() {
        let collector = self.makeDebtCollector()
        let delegate = DebtCollectorTestDelegate()
        collector.delegate = delegate
        let time = collector.time
        let dataStore = collector.dataStore
        
        let register = PropertyRegister(uuid: "random", address: MapPoint(x: 0, y: 0), playerUUID: "player", type: .land)
        dataStore.create(register)
        
        var updatedRegister: PropertyRegister? = dataStore.find(uuid: "random")
        XCTAssertEqual(updatedRegister?.status, .normal)
        
        XCTAssertEqual(delegate.notifuUUID.count, 0)
        collector.executeDebts()
        XCTAssertEqual(delegate.notifuUUID.count, 0)
        time.nextMonth()
        collector.executeDebts()
        XCTAssertEqual(delegate.notifuUUID.count, 1)
        time.nextMonth()
        collector.executeDebts()
        XCTAssertEqual(delegate.notifuUUID.count, 2)
        
        updatedRegister = dataStore.find(uuid: "random")
        XCTAssertEqual(updatedRegister?.status, .blockedByDebtCollector)
    }
    
    func test_propertyPutOnSale() {
        let collector = self.makeDebtCollector()
        let delegate = DebtCollectorTestDelegate()
        collector.delegate = delegate
        let time = collector.time
        let dataStore = collector.dataStore
        let address = MapPoint(x: 0, y: 0)
        
        let land = Land(address: address, name: "Some Name", ownerUUID: "player")
        let landUUID = dataStore.create(land)
        let register = PropertyRegister(uuid: landUUID, address: address, playerUUID: "player", type: .land)
        dataStore.create(register)
        collector.realEstateAgent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        
        XCTAssertFalse(collector.realEstateAgent.isForSale(address: address))
        for _ in (1...3) {
            collector.executeDebts()
            time.nextMonth()
        }
        XCTAssertTrue(collector.realEstateAgent.isForSale(address: address))
    }
    
    private func makeDebtCollector() -> DebtCollector {
        
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
        
        let collector = DebtCollector(realEstateAgent: agent)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: SystemPlayer.government.login, wallet: 0)
        dataStore.create(government)
        
        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: SystemPlayer.realEstateAgency.login, wallet: 0)
        dataStore.create(agency)
        
        let player = Player(uuid: "player", login: "Player", wallet: -300000)
        dataStore.create(player)
        return collector
    }
}

fileprivate class DebtCollectorTestDelegate: DebtCollectorDelegate {

    var notifuUUID: [(uuid: String, UINotification)] = []
    
    func notify(playerUUID: String, _ notification: UINotification) {
        self.notifuUUID.append((playerUUID, notification))
    }
}
