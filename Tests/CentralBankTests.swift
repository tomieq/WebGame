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
    
    func test_userToUserTransferWalletsUpdateNoIncomeTax() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 100)
        let receiver = Player(uuid: "receiver", login: "user2", wallet: 100)
        dataStore.create(payer)
        dataStore.create(receiver)
        
        let taxRates = TaxRates()
        taxRates.incomeTax = 0
        
        let invoice = Invoice(title: "money transfer", grossValue: 30, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction)
        
        XCTAssertEqual(dataStore.find(uuid: "payer")?.wallet, 70)
        XCTAssertEqual(dataStore.find(uuid: "receiver")?.wallet, 130)
    }
    
    func test_unknownPayer() {
        let dataStore = DataStoreMemoryProvider()
        
        let taxRates = TaxRates()
        
        let invoice = Invoice(title: "money transfer", grossValue: 30, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        
        XCTAssertThrowsError(try CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction)){ error in
            XCTAssertEqual(error as? FinancialTransactionError, .payerNotFound)
        }
    }
    
    func test_unknownRecipient() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 100)
        dataStore.create(payer)
        
        let taxRates = TaxRates()
        
        let invoice = Invoice(title: "money transfer", grossValue: 30, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        
        XCTAssertThrowsError(try CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction)){ error in
            XCTAssertEqual(error as? FinancialTransactionError, .recipientNotFound)
        }
    }
    
    func test_notEnoughMoney() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 100)
        let receiver = Player(uuid: "receiver", login: "user2", wallet: 100)
        dataStore.create(payer)
        dataStore.create(receiver)
        
        let taxRates = TaxRates()
        
        let invoice = Invoice(title: "money transfer", grossValue: 150, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        
        XCTAssertThrowsError(try CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction)){ error in
            XCTAssertEqual(error as? FinancialTransactionError, .notEnoughMoney)
        }
    }
    
    func test_negativeMoneyAmount() {
        let dataStore = DataStoreMemoryProvider()
        
        let taxRates = TaxRates()
        
        let invoice = Invoice(title: "money transfer", grossValue: -90, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        
        XCTAssertThrowsError(try CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction)){ error in
            XCTAssertEqual(error as? FinancialTransactionError, .negativeTransactionValue)
        }
    }
    
    func test_valueOfIncomeTax() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 900)
        let receiver = Player(uuid: "receiver", login: "user2", wallet: 100)
        dataStore.create(payer)
        dataStore.create(receiver)
        
        let taxRates = TaxRates()
        taxRates.incomeTax = 0.5
        
        let invoice = Invoice(title: "money transfer", netValue: 100, taxRate: 0.1)
        let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        let result = CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction)
        if case .success = result {
            
        } else {
            XCTFail()
        }
        XCTAssertEqual(dataStore.find(uuid: "receiver")?.wallet, 150)
    }
    
    func test_valueAddedTax() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 900)
        let receiver = Player(uuid: "receiver", login: "user2", wallet: 100)
        dataStore.create(payer)
        dataStore.create(receiver)
        
        let taxRates = TaxRates()
        taxRates.incomeTax = 0
        
        let invoice = Invoice(title: "money transfer", netValue: 100, taxRate: 0.5)
        let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        let result = CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction)
        if case .success = result {
            
        } else {
            XCTFail()
        }
        XCTAssertEqual(dataStore.find(uuid: "payer")?.wallet, 750)
    }
    
    func test_tooHighIncomeTax() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 900)
        let receiver = Player(uuid: "receiver", login: "user2", wallet: 100)
        dataStore.create(payer)
        dataStore.create(receiver)
        
        let taxRates = TaxRates()
        taxRates.incomeTax = 1.2
        
        let invoice = Invoice(title: "money transfer", grossValue: 100, taxRate: 0.1)
        let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        let result = CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction)
        if case .success = result {
            
        } else {
            XCTFail()
        }
        XCTAssertEqual(dataStore.find(uuid: "payer")?.wallet, 800)
        XCTAssertEqual(dataStore.find(uuid: "receiver")?.wallet, 100)
    }
}
