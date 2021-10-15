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

    func test_createPlayer() {
        let playerCreateRequest = PlayerCreateRequest(login: "tester", type: .user, wallet: 50)
        let id = DataStore.provider.createPlayer(playerCreateRequest)
        let player = DataStore.provider.getPlayer(id: id)
        XCTAssertEqual(playerCreateRequest.login, player?.login)
        DataStore.provider.removePlayer(id: id)
        XCTAssertNil(DataStore.provider.getPlayer(id: id))
    }
    
    func test_updateWallet() {
        let playerCreateRequest = PlayerCreateRequest(login: "tester", type: .user, wallet: 50)
        let id = DataStore.provider.createPlayer(playerCreateRequest)
        DataStore.provider.update(PlayerMutation(id: id, attributes: [.wallet(110)]))
        let player = DataStore.provider.getPlayer(id: id)
        XCTAssertEqual(player?.wallet, 110)
        DataStore.provider.removePlayer(id: id)
        XCTAssertNil(DataStore.provider.getPlayer(id: id))
    }
}
