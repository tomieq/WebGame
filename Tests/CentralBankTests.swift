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
        
        let centralBank = self.makeCentralBank()
        
        centralBank.taxRates.incomeTax = 0
        
        let payer = Player(uuid: "payer2", login: "user1", wallet: 100)
        centralBank.dataStore.create(payer)
        let receiver = Player(uuid: "receiver2", login: "receiver", wallet: 100)
        centralBank.dataStore.create(receiver)
        
        let invoice = Invoice(title: "money transfer", grossValue: 30, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerUUID: "payer2", recipientUUID: "receiver2", invoice: invoice, type: .realEstateTrade)
        
        XCTAssertNoThrow(try centralBank.process(financialTransaction))
        XCTAssertEqual(centralBank.dataStore.find(uuid: "payer2")?.wallet, 70)
        XCTAssertEqual(centralBank.dataStore.find(uuid: "receiver2")?.wallet, 130)
    }
    
    func test_unknownPayer() {
        let centralBank = self.makeCentralBank()
        
        let invoice = Invoice(title: "money transfer", grossValue: 30, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerUUID: "payer2", recipientUUID: "receiver", invoice: invoice, type: .incomeTaxFree)
        
        XCTAssertThrowsError(try centralBank.process(financialTransaction)){ error in
            XCTAssertEqual(error as? FinancialTransactionError, .payerNotFound)
        }
    }
    
    func test_unknownRecipient() {
        let centralBank = self.makeCentralBank()
        
        let invoice = Invoice(title: "money transfer", grossValue: 30, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerUUID: "payer", recipientUUID: "receiver2", invoice: invoice, type: .incomeTaxFree)
        
        XCTAssertThrowsError(try centralBank.process(financialTransaction)){ error in
            XCTAssertEqual(error as? FinancialTransactionError, .recipientNotFound)
        }
    }
    
    func test_notEnoughMoney() {
        let centralBank = self.makeCentralBank()
        
        let invoice = Invoice(title: "money transfer", grossValue: 150, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerUUID: "payer", recipientUUID: "receiver", invoice: invoice, type: .incomeTaxFree)
        
        XCTAssertThrowsError(try centralBank.process(financialTransaction)){ error in
            XCTAssertEqual(error as? FinancialTransactionError, .notEnoughMoney)
        }
    }
    
    func test_ignoreWalletCapacity() {
        let centralBank = self.makeCentralBank()
        
        let invoice = Invoice(title: "money transfer", grossValue: 150, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerUUID: "payer2", recipientUUID: "receiver2", invoice: invoice, type: .incomeTaxFree)
        
        let payer = Player(uuid: "payer2", login: "user1", wallet: 0)
        centralBank.dataStore.create(payer)
        let receiver = Player(uuid: "receiver2", login: "receiver", wallet: 0)
        centralBank.dataStore.create(receiver)
        
        XCTAssertNoThrow(try centralBank.process(financialTransaction, checkWalletCapacity: false))
        XCTAssertEqual(centralBank.dataStore.find(uuid: "payer2")?.wallet, -150)
    }
    
    func test_negativeMoneyAmount() {
        let centralBank = self.makeCentralBank()
        
        let invoice = Invoice(title: "money transfer", grossValue: -90, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerUUID: "payer", recipientUUID: "receiver", invoice: invoice, type: .incomeTaxFree)
        
        XCTAssertThrowsError(try centralBank.process(financialTransaction)){ error in
            XCTAssertEqual(error as? FinancialTransactionError, .negativeTransactionValue)
        }
    }
    
    func test_moneyTransferWalletValues() {
        let centralBank = self.makeCentralBank()
        centralBank.taxRates.incomeTax = 0
        
        let payer = Player(uuid: "payer2", login: "user1", wallet: 100)
        centralBank.dataStore.create(payer)
        let receiver = Player(uuid: "receiver2", login: "receiver", wallet: 0)
        centralBank.dataStore.create(receiver)
        
        let invoice = Invoice(title: "money transfer", netValue: 100, taxRate: 0)
        let financialTransaction = FinancialTransaction(payerUUID: "payer2", recipientUUID: "receiver2", invoice: invoice, type: .incomeTaxFree)
        XCTAssertNoThrow(try centralBank.process(financialTransaction))
        XCTAssertEqual(centralBank.dataStore.find(uuid: "payer2")?.wallet, 0)
        XCTAssertEqual(centralBank.dataStore.find(uuid: "receiver2")?.wallet, 100)
    }
    
    func test_valueOfIncomeTax() {
        let centralBank = self.makeCentralBank()
        centralBank.taxRates.incomeTax = 0.5
        
        
        let payer = Player(uuid: "payer2", login: "user1", wallet: 900)
        centralBank.dataStore.create(payer)
        let receiver = Player(uuid: "receiver2", login: "receiver", wallet: 100)
        centralBank.dataStore.create(receiver)
        
        let invoice = Invoice(title: "money transfer", netValue: 100, taxRate: 0.1)
        let financialTransaction = FinancialTransaction(payerUUID: "payer2", recipientUUID: "receiver2", invoice: invoice, type: .realEstateTrade)
        XCTAssertNoThrow(try centralBank.process(financialTransaction))
        XCTAssertEqual(centralBank.dataStore.find(uuid: "receiver2")?.wallet, 150)
    }
    
    func test_valueAddedTax() {
        let centralBank = self.makeCentralBank()
        centralBank.taxRates.incomeTax = 0
        
        let payer = Player(uuid: "payer2", login: "user1", wallet: 900)
        centralBank.dataStore.create(payer)
        let receiver = Player(uuid: "receiver2", login: "receiver", wallet: 100)
        centralBank.dataStore.create(receiver)
        
        let invoice = Invoice(title: "money transfer", netValue: 100, taxRate: 0.5)
        let financialTransaction = FinancialTransaction(payerUUID: "payer2", recipientUUID: "receiver2", invoice: invoice, type: .incomeTaxFree)
        XCTAssertNoThrow(try centralBank.process(financialTransaction))
        XCTAssertEqual(centralBank.dataStore.find(uuid: "payer2")?.wallet, 750)
    }
    
    func test_tooHighIncomeTax() {
        let centralBank = self.makeCentralBank()
        centralBank.taxRates.incomeTax = 1.2
        
        let payer = Player(uuid: "payer2", login: "user1", wallet: 900)
        centralBank.dataStore.create(payer)
        let receiver = Player(uuid: "receiver2", login: "receiver", wallet: 100)
        centralBank.dataStore.create(receiver)
        
        let invoice = Invoice(title: "money transfer", grossValue: 100, taxRate: 0.1)
        let financialTransaction = FinancialTransaction(payerUUID: "payer2", recipientUUID: "receiver2", invoice: invoice, type: .realEstateTrade)
        XCTAssertNoThrow(try centralBank.process(financialTransaction))
        XCTAssertEqual(centralBank.dataStore.find(uuid: "payer2")?.wallet, 800)
        XCTAssertEqual(centralBank.dataStore.find(uuid: "receiver2")?.wallet, 100)
    }
    
    func test_multipleThreadTransfers() {
        let centralBank = self.makeCentralBank()
        centralBank.taxRates.incomeTax = 0
        
        let payer = Player(uuid: "payer2", login: "user1", wallet: 190000)
        centralBank.dataStore.create(payer)
        let receiver = Player(uuid: "receiver2", login: "receiver", wallet: 0)
        centralBank.dataStore.create(receiver)
        
        let iterations = 500

        let expectations = (0...iterations-1).map { _ in XCTestExpectation(description: "Financial transaction") }
        
        
        for i in 0...iterations-1 {
            let queue = DispatchQueue(label: "queue\(i)", qos: .background, attributes: .concurrent)
            queue.async {
                let invoice = Invoice(title: "money transfer", netValue: 100, taxRate: 0.1)
                let financialTransaction = FinancialTransaction(payerUUID: "payer2", recipientUUID: "receiver2", invoice: invoice, type: .incomeTaxFree)
                try? centralBank.process(financialTransaction)
                expectations[i].fulfill()
            }
        }
        wait(for: expectations, timeout: 2)
        
        let rich: Player? = centralBank.dataStore.find(uuid: "receiver2")
        XCTAssertEqual(rich?.wallet, iterations.double * 100)
    }
    
    func test_refundIncomeTax_fullRefund() {
        let centralBank = self.makeCentralBank()
        centralBank.taxRates.incomeTax = 0.2
        
        let invoice = Invoice(title: "sell", netValue: 100, taxRate: 0.08)
        let transaction = FinancialTransaction(payerUUID: "payer", recipientUUID: "receiver", invoice: invoice, type: .realEstateTrade)
        centralBank.refundIncomeTax(transaction: transaction, costs: 100)
        
        let player: Player? = centralBank.dataStore.find(uuid: "receiver")
        XCTAssertEqual(player?.wallet, 20)
    }
    
    func test_refundIncomeTax_partialRefund() {
        let centralBank = self.makeCentralBank()
        centralBank.taxRates.incomeTax = 0.2
        
        
        let invoice = Invoice(title: "sell", netValue: 1000, taxRate: 0.08)
        let transaction = FinancialTransaction(payerUUID: "payer", recipientUUID: "receiver", invoice: invoice, type: .incomeTaxFree)
        centralBank.refundIncomeTax(transaction: transaction, costs: 500)
        
        let player: Player? = centralBank.dataStore.find(uuid: "receiver")
        XCTAssertEqual(player?.wallet, 100)
    }
    
    private func makeCentralBank() -> CentralBank {
        
        let dataStore = DataStoreMemoryProvider()
        let payer = Player(uuid: "payer", login: "user1", wallet: 0)
        dataStore.create(payer)
        let receiver = Player(uuid: "receiver", login: "receiver", wallet: 0)
        dataStore.create(receiver)
        
        let taxRates = TaxRates()
        taxRates.incomeTax = 0.2
        let time = GameTime()
        
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates, time: time)
        return centralBank
    }
}
