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
        let playerUpdated: Player? = dataStore.find(uuid: id)
        XCTAssertEqual(playerUpdated?.login, player.login)
    }

    func test_createWithForcedUUID() {
        let dataStore = DataStoreMemoryProvider()
        let player = Player(uuid: "custom1", login: "tester", wallet: 50)
        let id = dataStore.create(player)
        XCTAssertEqual(id, "custom1")
        let retrievedPlayer: Player? = dataStore.find(uuid: "custom1")
        XCTAssertNotNil(retrievedPlayer)
    }

    func test_delete() {
        let dataStore = DataStoreMemoryProvider()
        let player = Player(login: "tester", wallet: 50)
        let id = dataStore.create(player)
        var retrievedPlayer: Player? = dataStore.find(uuid: id)
        XCTAssertNotNil(retrievedPlayer)
        dataStore.removePlayer(id: id)
        retrievedPlayer = dataStore.find(uuid: id)
        XCTAssertNil(retrievedPlayer)
    }

    func test_updateWallet() {
        let dataStore = DataStoreMemoryProvider()
        let player = Player(login: "tester", wallet: 50)
        let id = dataStore.create(player)
        dataStore.update(PlayerMutation(uuid: id, attributes: [.wallet(110)]))
        let playerUpdated: Player? = dataStore.find(uuid: id)
        XCTAssertEqual(playerUpdated?.wallet, 110)
    }
}
