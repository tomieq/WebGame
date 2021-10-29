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
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
    }
    
    func test_notEnoughMoney() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 90)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)

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
        let bet = FootballBet(matchUUID: "876204", playerUUID: "gambler", money: 100, expectedResult: .team1Win)

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
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)

        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        XCTAssertThrowsError(try bookie.makeBet(bet: bet)){ error in
            XCTAssertEqual(error as? MakeBetError, .canNotBetTwice)
        }
    }
    
    func test_winMoneyTransfer() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 100)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 50000)
        bookie.centralBank.dataStore.create(bookmaker)
        
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        
        bookie.upcomingMatch.setResult(goals: (1, 0))
        let winRatio: Double = bookie.upcomingMatch.team1WinsRatio
        XCTAssertEqual(winRatio, bookie.upcomingMatch.resultRatio(.team1Win))
        bookie.nextMonth()
        XCTAssertEqual(winRatio, bookie.lastMonthMatch?.resultRatio(.team1Win))
        XCTAssertEqual(winRatio, bookie.lastMonthMatch?.winRatio)
        bookie.nextMonth()
        bookie.nextMonth()
        let winner: Player? = bookie.centralBank.dataStore.find(uuid: "gambler")
        XCTAssertGreaterThan(winner?.wallet ?? 0, 100)
    }
    
    func test_makeBetNotification() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 100)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)
        
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
    
    func test_winNotifications() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 100)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 50000)
        bookie.centralBank.dataStore.create(bookmaker)
        
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        
        bookie.upcomingMatch.setResult(goals: (1, 0))
        
        let delegate = BookieDelegate()
        bookie.delegate = delegate
        
        bookie.nextMonth()
        XCTAssertEqual(delegate.notifuUUID.count, 1)
        XCTAssertEqual(delegate.notifuUUID[safeIndex: 0]?.uuid, "gambler")
        XCTAssertEqual(delegate.notifuUUID[safeIndex: 0]?.1.level, .success)
    }
    
    func test_looseNotifications() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 100)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 50000)
        bookie.centralBank.dataStore.create(bookmaker)
        
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        
        bookie.upcomingMatch.setResult(goals: (0, 1))
        
        let delegate = BookieDelegate()
        bookie.delegate = delegate
        
        bookie.nextMonth()
        XCTAssertEqual(delegate.notifuUUID.count, 1)
        XCTAssertEqual(delegate.notifuUUID[safeIndex: 0]?.uuid, "gambler")
        XCTAssertEqual(delegate.notifuUUID[safeIndex: 0]?.1.level, .warning)
    }
    
    func test_archiveRotation() {
        let bookie = self.makeBookie()
        XCTAssertEqual(bookie.getArchive().count, 0)
        bookie.nextMonth()
        XCTAssertEqual(bookie.getArchive().count, 1)
        bookie.nextMonth()
        XCTAssertEqual(bookie.getArchive().count, 2)
        bookie.nextMonth()
        XCTAssertEqual(bookie.getArchive().count, 3)
        bookie.nextMonth()
        XCTAssertEqual(bookie.getArchive().count, 4)
        bookie.nextMonth()
        XCTAssertEqual(bookie.getArchive().count, 5)
        bookie.nextMonth()
        XCTAssertEqual(bookie.getArchive().count, 5)
    }
    
    func test_betsInArchive() {
        let bookie = self.makeBookie()
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 100)
        bookie.centralBank.dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        bookie.centralBank.dataStore.create(bookmaker)
        
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        
        
        XCTAssertEqual(bookie.getArchive().count, 0)
        bookie.nextMonth()
        XCTAssertEqual(bookie.getArchive().count, 1)
        XCTAssertEqual(bookie.getArchive()[safeIndex: 0]?.bets.count, 1)
        
        bookie.nextMonth()
        XCTAssertEqual(bookie.getArchive().count, 2)
        XCTAssertEqual(bookie.getArchive()[safeIndex: 0]?.bets.count, 1)
        XCTAssertEqual(bookie.getArchive()[safeIndex: 1]?.bets.count, 0)
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

fileprivate class BookieDelegate: FootballBookieDelegate {
    var walletUUID: [String] = []
    var notifuUUID: [(uuid: String, UINotification)] = []
    func syncWalletChange(playerUUID: String) {
        self.walletUUID.append(playerUUID)
    }
    
    func notify(playerUUID: String, _ notification: UINotification) {
        self.notifuUUID.append((playerUUID, notification))
    }
}
