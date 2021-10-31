//
//  RefereeTests.swift
//  
//
//  Created by Tomasz Kucharski on 31/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

class RefereeTests: XCTestCase {
    
    func test_tooSmallBribe() {
        let referee = Referee()
        
        XCTAssertThrowsError(try referee.bribe(playerUUID: "gambler", matchUUID: "", amount: 100.0)){ error in
            XCTAssertEqual(error as? RefereeError, .bribeTooSmall)
        }
    }
    
    func test_delegateNotSet() {
        let referee = Referee()
        
        XCTAssertThrowsError(try referee.bribe(playerUUID: "gambler", matchUUID: "nonExisting", amount: 20000.0)){ error in
            XCTAssertEqual(error as? RefereeError, .matchNotFound)
        }
    }
    
    func test_bribeMatchHasEnded() {
        let referee = Referee()
        let bookie = self.makeBookie()
        referee.delegate = bookie
        
        let matchUUID = bookie.upcomingMatch.uuid
        bookie.nextMonth()
        XCTAssertThrowsError(try referee.bribe(playerUUID: "gambler", matchUUID: matchUUID, amount: 20000.0)){ error in
            XCTAssertEqual(error as? RefereeError, .outOfTime)
        }
    }
    
    func test_betNotFound() {
        let referee = Referee()
        let bookie = self.makeBookie()
        referee.delegate = bookie
        
        
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 100)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        
        let matchUUID = bookie.upcomingMatch.uuid
        XCTAssertThrowsError(try referee.bribe(playerUUID: "gambler", matchUUID: matchUUID, amount: 20000.0)){ error in
            XCTAssertEqual(error as? RefereeError, .betNotFound)
        }
    }
    
    func test_unsucessfulBribeNotEnoughMoney() {
        let referee = Referee()
        let bookie = self.makeBookie()
        referee.delegate = bookie
        
        
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 100)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        
        let matchUUID = bookie.upcomingMatch.uuid
        XCTAssertNoThrow(try bookie.makeBet(bet: FootballBet(matchUUID: matchUUID, playerUUID: "gambler", money: 100, expectedResult: .team1Win)))
        
        XCTAssertThrowsError(try referee.bribe(playerUUID: "gambler", matchUUID: matchUUID, amount: 20000.0)){ error in
            XCTAssertEqual(error as? RefereeError, .financialProblem(.notEnoughMoney))
        }
    }
    
    func test_bribeDidSetTheResult() {
        let referee = Referee()
        let bookie = self.makeBookie()
        referee.delegate = bookie
        
        let matchUUID = bookie.upcomingMatch.uuid
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 100000)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        XCTAssertNoThrow(try bookie.makeBet(bet: FootballBet(matchUUID: matchUUID, playerUUID: "gambler", money: 100, expectedResult: .team1Win)))
        XCTAssertNoThrow(try referee.bribe(playerUUID: "gambler", matchUUID: matchUUID, amount: 20000.0))
        XCTAssertEqual(bookie.upcomingMatch.result, .team1Win)
    }
    
    func test_bribeFromTwoUsersBettingTheSame() {
        
    }
    
    func test_bribeFromTwoUsersBettingDifferent() {
        
    }
    
    func test_bribeFromUserWithoutEnoughMoneyInWallet() {
        
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
