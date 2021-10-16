//
//  CentralBankTests.swift
//  
//
//  Created by Tomasz Kucharski on 16/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class CentralBankTests: XCTestCase {
    
    func test_userToUserWalletsUpdate() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 100)
        let receiver = Player(uuid: "receiver", login: "user2", wallet: 100)
        dataStore.create(payer)
        dataStore.create(receiver)
        
        let invoice = Invoice(title: "money transfer", grossValue: 30, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        CentralBank(dataStore: dataStore).process(financialTransaction)
        
        XCTAssertEqual(dataStore.find(uuid: "payer")?.wallet, 70)
        let receiverWallet = dataStore.find(uuid: "receiver")?.wallet
        XCTAssertNotNil(receiverWallet)
        XCTAssertGreaterThan(receiverWallet ?? 0, 100.0)
        XCTAssertLessThan(receiverWallet ?? 0, 130.0)
    }
}
