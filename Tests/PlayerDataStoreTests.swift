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
        let playerCreateRequest = Player(login: "tester", type: .user, wallet: 50)
        let id = DataStore.provider.create(playerCreateRequest)
        let player = DataStore.provider.find(uuid: id)
        XCTAssertEqual(playerCreateRequest.login, player?.login)
        DataStore.provider.removePlayer(id: id)
        XCTAssertNil(DataStore.provider.find(uuid: id))
    }
    
    func test_updateWallet() {
        let playerCreateRequest = Player(login: "tester", type: .user, wallet: 50)
        let id = DataStore.provider.create(playerCreateRequest)
        DataStore.provider.update(PlayerMutation(id: id, attributes: [.wallet(110)]))
        let player = DataStore.provider.find(uuid: id)
        XCTAssertEqual(player?.wallet, 110)
        DataStore.provider.removePlayer(id: id)
        XCTAssertNil(DataStore.provider.find(uuid: id))
    }
    
    func test_payMoney() {
        let playerCreateRequest = Player(login: "tester", type: .user, wallet: 80)
        let id = DataStore.provider.create(playerCreateRequest)
        let player = DataStore.provider.find(uuid: id)
        player?.pay(70)
        XCTAssertNotEqual(player?.wallet, 10)
        let playerUpdated = DataStore.provider.find(uuid: id)
        XCTAssertEqual(playerUpdated?.wallet, 10)
        DataStore.provider.removePlayer(id: id)
        XCTAssertNil(DataStore.provider.find(uuid: id))
    }
    
    func test_receiveMoney() {
        let playerCreateRequest = Player(login: "tester", type: .user, wallet: 80)
        let id = DataStore.provider.create(playerCreateRequest)
        let player = DataStore.provider.find(uuid: id)
        player?.receiveMoney(100)
        XCTAssertNotEqual(player?.wallet, 180)
        let playerUpdated = DataStore.provider.find(uuid: id)
        XCTAssertEqual(playerUpdated?.wallet, 180)
        DataStore.provider.removePlayer(id: id)
        XCTAssertNil(DataStore.provider.find(uuid: id))
    }
}
