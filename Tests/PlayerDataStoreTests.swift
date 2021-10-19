//
//  PlayerDataStoreTests.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class PlayerDataStoreTests: XCTestCase {

    func test_create() {
        let dataStore = DataStoreMemoryProvider()
        let player = Player(login: "tester", wallet: 50)
        let id = dataStore.create(player)
        let playerUpdated = dataStore.find(uuid: id)
        XCTAssertEqual(playerUpdated?.login, player.login)
    }
    
    func test_createWithForcedUUID() {
        let dataStore = DataStoreMemoryProvider()
        let player = Player(uuid: "custom1", login: "tester", wallet: 50)
        let id = dataStore.create(player)
        XCTAssertEqual(id, "custom1")
        XCTAssertNotNil(dataStore.find(uuid: "custom1"))
    }
    
    func test_delete() {
        let dataStore = DataStoreMemoryProvider()
        let player = Player(login: "tester", wallet: 50)
        let id = dataStore.create(player)
        XCTAssertNotNil(dataStore.find(uuid: id))
        dataStore.removePlayer(id: id)
        XCTAssertNil(dataStore.find(uuid: id))
    }
    
    func test_updateWallet() {
        let dataStore = DataStoreMemoryProvider()
        let player = Player(login: "tester", wallet: 50)
        let id = dataStore.create(player)
        dataStore.update(PlayerMutation(id: id, attributes: [.wallet(110)]))
        let playerUpdated = dataStore.find(uuid: id)
        XCTAssertEqual(playerUpdated?.wallet, 110)
    }
}
