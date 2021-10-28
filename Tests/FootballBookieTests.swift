//
//  FootballBookieTests.swift
//  
//
//  Created by Tomasz Kucharski on 28/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

class FootballBookieTests: XCTestCase {
    
    func test_properBet() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gampler", wallet: 100)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Won)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
    }
    
    func test_notEnoughMoney() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gampler", wallet: 90)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Won)

        XCTAssertThrowsError(try bookie.makeBet(bet: bet)){ error in
            XCTAssertEqual(error as? MakeBetError, .financialProblem(.notEnoughMoney))
        }
    }
    
    func test_invalidMatchUUID() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gampler", wallet: 400)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        let bet = FootballBet(matchUUID: "876204", playerUUID: "gambler", money: 100, expectedResult: .team1Won)

        XCTAssertThrowsError(try bookie.makeBet(bet: bet)){ error in
            XCTAssertEqual(error as? MakeBetError, .outOfTime)
        }
    }
    
    private func makeBookie() -> FootballBookie {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let time = GameTime()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates, time: time)
        let bookie = FootballBookie(centralBank: centralBank)
        return bookie
    }
}
