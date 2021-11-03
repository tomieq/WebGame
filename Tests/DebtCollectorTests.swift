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
        let address = MapPoint(x: 0, y: 0)
        
        let register = PropertyRegister(uuid: "random", address: address, playerUUID: "player", type: .land)
        dataStore.create(register)
        collector.realEstateAgent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        dataStore.create(Land(address: address, ownerUUID: "player"))
        
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
    
    func test_choosePropertyForExecution_bestMatch() {
        let collector = self.makeDebtCollector()
        
        var options: [PropertyForDebtExecution] = []
        
        for i in (1...8) {
            let register = PropertyRegister(uuid: i.string, address: MapPoint(x: i, y: 0), playerUUID: "player", type: .land)
            let option = PropertyForDebtExecution(register: register, value: i.double * 10000)
            options.append(option)
        }
        let chosenProperties = collector.chooseProperties(options, debt: 30000)
        XCTAssertEqual(chosenProperties.count, 1)
        XCTAssertEqual(chosenProperties[safeIndex: 0]?.value, 40000)
    }
    
    func test_putPropertyOnSale_addAnother_afterNoSale() {
        let collector = self.makeDebtCollector()
        let delegate = DebtCollectorTestDelegate()
        collector.delegate = delegate
        collector.montlyPropertyPriceReduction = 0.4
        
        let time = collector.time
        let dataStore = collector.dataStore
        let addresses = [MapPoint(x: 0, y: 0), MapPoint(x: 1, y: 1)]
        
        for n in (0...1) {
            let address = addresses[n]
            let land = Land(address: address, name: "Land \(n)", ownerUUID: "player")
            let landUUID = dataStore.create(land)
            let register = PropertyRegister(uuid: landUUID, address: address, playerUUID: "player", type: .land)
            dataStore.create(register)
            collector.realEstateAgent.mapManager.map.replaceTile(tile: GameMapTile(address: address, type: .soldLand))
        }
        let landValue = collector.realEstateAgent.propertyValuer.estimateValue(addresses[0]) ?? 1
        dataStore.update(PlayerMutation(uuid: "player", attributes: [.wallet(-1.0 * landValue * 0.5)]))
        
        XCTAssertFalse(collector.realEstateAgent.isForSale(address: addresses[0]))
        XCTAssertFalse(collector.realEstateAgent.isForSale(address: addresses[1]))
        for _ in (1...3) {
            collector.executeDebts()
            time.nextMonth()
        }
        XCTAssertEqual(collector.realEstateAgent.getAllSaleOffers(buyerUUID: "buyer").count, 1)
        collector.executeDebts()
        time.nextMonth()
        XCTAssertEqual(collector.realEstateAgent.getAllSaleOffers(buyerUUID: "buyer").count, 2)
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
    
    func notifyEveryone(_ notification: UINotification, exceptUserUUIDs: [String]) {
        
    }
}
