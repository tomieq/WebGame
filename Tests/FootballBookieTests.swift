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
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 100)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Won)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
    }
    
    func test_notEnoughMoney() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 90)
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
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 400)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        let bet = FootballBet(matchUUID: "876204", playerUUID: "gambler", money: 100, expectedResult: .team1Won)

        XCTAssertThrowsError(try bookie.makeBet(bet: bet)){ error in
            XCTAssertEqual(error as? MakeBetError, .outOfTime)
        }
    }
    
    func test_doubleBet() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 400)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Won)

        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        XCTAssertThrowsError(try bookie.makeBet(bet: bet)){ error in
            XCTAssertEqual(error as? MakeBetError, .canNotBetTwice)
        }
    }
    
    func test_winMoneyTransfer() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 700)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        var bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Won)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 200, expectedResult: .team2Won)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 400, expectedResult: .draw)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        
        bookie.nextMonth()
        let result = bookie.lastMonthMatch?.result
        let ratio = bookie.lastMonthMatch?.ratio ?? 0
        XCTAssertNotNil(result)
        var expectedWin: Double = 0
        switch result ?? .draw {
            
        case .team1Won:
            expectedWin = 100 * ratio
        case .team2Won:
            expectedWin = 200 * ratio
        case .draw:
            expectedWin = 400 * ratio
        }
        bookie.nextMonth()
        bookie.nextMonth()
        let winner: Player? = bookie.centralBank.dataStore.find(uuid: "gambler")
        XCTAssertEqual(expectedWin.rounded(toPlaces: 0), winner?.wallet)
    }
    
    func test_makeBetNotification() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 100)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Won)
        
        class BookieDelegate: FootballBookieDelegate {
            var walletUUID: [String] = []
            var notifuUUID: [(uuid: String, UINotification)] = []
            func syncWalletChange(playerUUID: String) {
                self.walletUUID.append(playerUUID)
            }
            
            func notify(playerUUID: String, _ notification: UINotification) {
                self.notifuUUID.append((playerUUID, notification))
            }
        }
        let delegate = BookieDelegate()
        bookie.delegate = delegate
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        XCTAssertEqual(delegate.walletUUID.count, 1)
        XCTAssertTrue(delegate.walletUUID.contains("gambler"))
        XCTAssertEqual(delegate.notifuUUID.count, 1)
        XCTAssertEqual(delegate.notifuUUID[safeIndex: 0]?.uuid, "gambler")
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
