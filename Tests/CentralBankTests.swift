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
        
        XCTAssertNoThrow(try CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction))
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
    
    func test_moneyTransferWalletValues() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 100)
        let receiver = Player(uuid: "receiver", login: "user2", wallet: 0)
        dataStore.create(payer)
        dataStore.create(receiver)
        
        let taxRates = TaxRates()
        taxRates.incomeTax = 0
        
        let invoice = Invoice(title: "money transfer", netValue: 100, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        XCTAssertNoThrow(try CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction))
        XCTAssertEqual(dataStore.find(uuid: "payer")?.wallet, 0)
        XCTAssertEqual(dataStore.find(uuid: "receiver")?.wallet, 100)
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
        XCTAssertNoThrow(try CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction))
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
        XCTAssertNoThrow(try CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction))
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
        XCTAssertNoThrow(try CentralBank(dataStore: dataStore, taxRates: taxRates).process(financialTransaction))
        XCTAssertEqual(dataStore.find(uuid: "payer")?.wallet, 800)
        XCTAssertEqual(dataStore.find(uuid: "receiver")?.wallet, 100)
    }
    
    func test_multipleThreadTransfers() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 190000)
        let receiver = Player(uuid: "receiver", login: "user2", wallet: 0)
        dataStore.create(payer)
        dataStore.create(receiver)
        
        let taxRates = TaxRates()
        taxRates.incomeTax = 0
        
        let iterations = 1000

        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        let expectations = (0...iterations-1).map { _ in XCTestExpectation(description: "Financial transaction") }
        
        for i in 0...iterations-1 {
            let queue = DispatchQueue(label: "queue\(i)", qos: .background, attributes: .concurrent)
            queue.async {
                let invoice = Invoice(title: "money transfer", netValue: 100, taxRate: 0.1)
                let financialTransaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
                try? centralBank.process(financialTransaction)
                expectations[i].fulfill()
            }
        }
        wait(for: expectations, timeout: 1)
        let rich: Player? = dataStore.find(uuid: "receiver")
        XCTAssertEqual(rich?.wallet, iterations.double * 100)
    }
    
    func test_refundIncomeTax_fullRefund() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 0)
        dataStore.create(payer)
        let receiver = Player(uuid: "receiver", login: "receiver", wallet: 0)
        dataStore.create(receiver)
        
        let taxRates = TaxRates()
        taxRates.incomeTax = 0.2
        
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let invoice = Invoice(title: "sell", netValue: 100, taxRate: 0.08)
        let transaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        centralBank.refundIncomeTax(transaction: transaction, costs: 100)
        
        let player: Player? = dataStore.find(uuid: "receiver")
        XCTAssertEqual(player?.wallet, 20)
    }
    
    func test_refundIncomeTax_partialRefund() {
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 0)
        dataStore.create(payer)
        let receiver = Player(uuid: "receiver", login: "receiver", wallet: 0)
        dataStore.create(receiver)
        
        let taxRates = TaxRates()
        taxRates.incomeTax = 0.2
        
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let invoice = Invoice(title: "sell", netValue: 1000, taxRate: 0.08)
        let transaction = FinancialTransaction(payerID: "payer", recipientID: "receiver", invoice: invoice)
        centralBank.refundIncomeTax(transaction: transaction, costs: 500)
        
        let player: Player? = dataStore.find(uuid: "receiver")
        XCTAssertEqual(player?.wallet, 100)
    }
}
