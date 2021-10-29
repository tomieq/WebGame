//
//  PoliceTests.swift
//  
//
//  Created by Tomasz Kucharski on 29/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

class PoliceTests: XCTestCase {
    
    func test_cleanFootballBets() {
        let police = self.makePolice()
        let bookie = police.footballBookie
        
        for _ in (1...6) {
            self.makeCleandBet(bookie)
            bookie.nextMonth()
            police.checkFootballMatches()
            XCTAssertEqual(police.investigations.count, 0)
        }
    }

    func test_bribedFootballMatches_oneAfterAnother() {
        let police = self.makePolice()
        let bookie = police.footballBookie
        
        self.makeBribedBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
        
        self.makeBribedBet(bookie)
        bookie.upcomingMatch.setResult(goals: (1, 0), briberUUID: "gambler")
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 1)
        
        self.makeCleandBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 1)
        
        self.makeCleandBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 1)
        
        self.makeCleandBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
    }
    
    func test_bribedFootballMatches_withADelay() {
        let police = self.makePolice()
        let bookie = police.footballBookie
        
        self.makeBribedBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
        
        self.makeCleandBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
        
        self.makeCleandBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
        
        self.makeBribedBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 1)
        
        self.makeCleandBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
    }
    
    func test_bribedFootballMatches_withA5MonthDelay() {
        let police = self.makePolice()
        let bookie = police.footballBookie
        
        self.makeBribedBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
        
        self.makeCleandBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
        
        self.makeCleandBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
        
        self.makeCleandBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
        
        self.makeBribedBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 1)
    }
    

    func test_bribedFootballMatches_checkInvestigationNotificationSameBriber() {
        let police = self.makePolice()
        let bookie = police.footballBookie
        let delegate = PoliceTestDelegate()
        police.delegate = delegate
        
        self.makeBribedBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
        XCTAssertEqual(delegate.notifuUUID.count, 0)
        
        self.makeBribedBet(bookie)
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 1)
        XCTAssertEqual(delegate.notifuUUID.count, 1)
        XCTAssertEqual(delegate.notifuUUID[safeIndex: 0]?.uuid, "gambler")
    }
    
    func test_bribedFootballMatches_checkInvestigationNotificationDifferentBribers() {
        let police = self.makePolice()
        let bookie = police.footballBookie
        let delegate = PoliceTestDelegate()
        police.delegate = delegate
        
        var bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        bookie.upcomingMatch.setResult(goals: (1, 0), briberUUID: "gambler")
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 0)
        XCTAssertEqual(delegate.notifuUUID.count, 0)
        
        bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        bookie.upcomingMatch.setResult(goals: (1, 0), briberUUID: "secondGambler")
        bookie.nextMonth()
        police.checkFootballMatches()
        XCTAssertEqual(police.investigations.count, 1)
        XCTAssertEqual(delegate.notifuUUID.count, 2)
        XCTAssertEqual(delegate.notifuUUID[safeIndex: 0]?.uuid, "gambler")
        XCTAssertTrue(delegate.notifuUUID.contains{ $0.uuid == "gambler" })
        XCTAssertTrue(delegate.notifuUUID.contains{ $0.uuid == "secondGambler" })
    }
    
    private func makePolice() -> Police {
        let dataStore = DataStoreMemoryProvider()
        let time = GameTime()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates, time: time)
        let bookie = FootballBookie(centralBank: centralBank)
        let court = Court(centralbank: centralBank)
        let police = Police(footballBookie: bookie, court: court)
        
        
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 1000000)
        dataStore.create(gambler)
        
        let bookmaker = Player(uuid: SystemPlayer.bookie.uuid, login: SystemPlayer.bookie.login, wallet: 0)
        dataStore.create(bookmaker)
        
        return police
    }
    
    private func makeBribedBet(_ bookie: FootballBookie) {
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
        bookie.upcomingMatch.setResult(goals: (1, 0), briberUUID: "gambler")
    }
    
    private func makeCleandBet(_ bookie: FootballBookie) {
        let bet = FootballBet(matchUUID: bookie.upcomingMatch.uuid, playerUUID: "gambler", money: 100, expectedResult: .team1Win)
        XCTAssertNoThrow(try bookie.makeBet(bet: bet))
    }
}

fileprivate class PoliceTestDelegate: PoliceDelegate {
    var walletUUID: [String] = []
    var notifuUUID: [(uuid: String, UINotification)] = []
    func syncWalletChange(playerUUID: String) {
        self.walletUUID.append(playerUUID)
    }
    
    func notify(playerUUID: String, _ notification: UINotification) {
        self.notifuUUID.append((playerUUID, notification))
    }
}
