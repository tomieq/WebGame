//
//  CourtTests.swift
//  
//
//  Created by Tomasz Kucharski on 29/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib


class CourtTests: XCTestCase {
    
    func test_registerNewCase() {
        let court = self.makeCourt()
        let bribeCase = FootballBriberyCase(accusedUUID: "gambler", illegalWin: 100, bribedReferees: ["Mike Poor"])
        court.registerNewCase(bribeCase)
        
        XCTAssertEqual(court.cases.count, 1)
    }
    
    func test_checkFootballBribery_FineWasIssued() {
        let court = self.makeCourt()
        let dataStore = court.centralbank.dataStore
        let bribeCase = FootballBriberyCase(accusedUUID: "gambler", illegalWin: 100, bribedReferees: ["Mike Poor"])
        court.registerNewCase(bribeCase)
        
        XCTAssertEqual(court.cases.count, 1)
        court.nextMonth()
        XCTAssertEqual(court.cases.count, 0)
        let guilty: Player? = dataStore.find(uuid: "gambler")
        XCTAssertEqual(guilty?.wallet, -300)
    }
    
    func test_checkFootballBribery_notifications() {
        let court = self.makeCourt()
        let delegate = CourtTestDelegate()
        court.delegate = delegate
        let bribeCase = FootballBriberyCase(accusedUUID: "gambler", illegalWin: 100, bribedReferees: ["Mike Poor"])
        court.registerNewCase(bribeCase)
        
        court.nextMonth()
        
        XCTAssertEqual(delegate.walletUUID.count, 1)
        XCTAssertTrue(delegate.walletUUID.contains("gambler"))
        XCTAssertEqual(delegate.notifuUUID.count, 1)
        XCTAssertTrue(delegate.notifuUUID.contains{ $0.uuid == "gambler"})
    }
    
    private func makeCourt() -> Court {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let time = GameTime()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates, time: time)
        let court = Court(centralbank: centralBank)
        
        
        let gambler = Player(uuid: "gambler", login: "gambler", wallet: 0)
        dataStore.create(gambler)
        
        let government = Player(uuid: SystemPlayer.government.uuid, login: SystemPlayer.government.login, wallet: 0)
        dataStore.create(government)
        return court
    }
}

fileprivate class CourtTestDelegate: CourtDelegate {
    var walletUUID: [String] = []
    var notifuUUID: [(uuid: String, UINotification)] = []
    func syncWalletChange(playerUUID: String) {
        self.walletUUID.append(playerUUID)
    }
    
    func notify(playerUUID: String, _ notification: UINotification) {
        self.notifuUUID.append((playerUUID, notification))
    }
}
