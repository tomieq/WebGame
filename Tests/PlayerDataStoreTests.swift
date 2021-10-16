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
        let playerCreateRequest = Player(login: "tester", type: .user, wallet: 50)
        let id = dataStore.create(playerCreateRequest)
        let player = dataStore.find(uuid: id)
        XCTAssertEqual(playerCreateRequest.login, player?.login)
    }
    
    func test_delete() {
        let dataStore = DataStoreMemoryProvider()
        let playerCreateRequest = Player(login: "tester", type: .user, wallet: 50)
        let id = dataStore.create(playerCreateRequest)
        XCTAssertNotNil(dataStore.find(uuid: id))
        dataStore.removePlayer(id: id)
        XCTAssertNil(dataStore.find(uuid: id))
    }
    
    func test_updateWallet() {
        let dataStore = DataStoreMemoryProvider()
        let playerCreateRequest = Player(login: "tester", type: .user, wallet: 50)
        let id = dataStore.create(playerCreateRequest)
        dataStore.update(PlayerMutation(id: id, attributes: [.wallet(110)]))
        let player = dataStore.find(uuid: id)
        XCTAssertEqual(player?.wallet, 110)
    }
}
