//
//  CentralBank.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

enum FinancialTransactionError: Error, Equatable {
    case negativeTransactionValue
    case payerNotFound
    case recipientNotFound
    case notEnoughMoney
    
    var description: String {
        switch self {
        case .negativeTransactionValue:
            return "Negative transaction value"
        case .payerNotFound:
            return "Payer not found!"
        case .recipientNotFound:
            return "Recipient not found!"
        case .notEnoughMoney:
            return "Not enough amount of money to finish the financial transaction"
        }
    }
}

class CentralBank {
    let dataStore: DataStoreProvider
    let taxRates: TaxRates
    let time: GameTime
    private let semaphore = DispatchSemaphore(value: 1)
    
    init(dataStore: DataStoreProvider, taxRates: TaxRates, time: GameTime) {
        self.dataStore = dataStore
        self.taxRates = taxRates
        self.time = time
    }
    
    func process(_ transaction: FinancialTransaction, checkWalletCapacity: Bool = true) throws {

        Logger.info("CentralBank", "New transaction \(transaction.toJSONString() ?? "")")
        
        guard transaction.invoice.total > 0 else {
            self.semaphore.signal()
            throw FinancialTransactionError.negativeTransactionValue
            
        }
        // let's block user's wallets so it won't be modified by anyone else
        self.semaphore.wait()
        guard let payer: Player = self.dataStore.find(uuid: transaction.payerUUID) else {
            self.semaphore.signal()
            Logger.error("CentralBank", "Transaction rejected. Payer not found (\(transaction.payerUUID)")
            throw FinancialTransactionError.payerNotFound
        }
        guard let recipient: Player = self.dataStore.find(uuid: transaction.recipientUUID) else {
            self.semaphore.signal()
            Logger.error("CentralBank", "Transaction rejected. Recipient not found (\(transaction.recipientUUID)")
            throw FinancialTransactionError.recipientNotFound
        }
        
        let government: Player? = self.dataStore.find(uuid: SystemPlayer.government.uuid)
        
        if checkWalletCapacity, payer.wallet < transaction.invoice.total {
            self.semaphore.signal()
            throw FinancialTransactionError.notEnoughMoney
        }
        
        // update payer's wallet
        payer.decreaseWallet(amount: transaction.invoice.total, self.dataStore)

        if !payer.isSystemPlayer {
            self.archive(playerID: payer.uuid, title: transaction.invoice.title, amount: -1 * transaction.invoice.total)
        }
        
        if recipient.uuid == government?.uuid, let government = government {
            government.increaseWallet(amount: transaction.invoice.total, self.dataStore)
        } else {
            // government takes income tax and VAT
            
            var incomeTax: Double = 0
            switch transaction.type {
            case .incomeTaxFree, .fine:
                incomeTax = 0;
            case .realEstateTrade, .services, .investments, .gambling:
                incomeTax = (transaction.invoice.netValue * self.taxRates.incomeTax).rounded(toPlaces: 0)
            }
            if incomeTax > transaction.invoice.netValue { incomeTax = transaction.invoice.netValue }
            let taxes = incomeTax + transaction.invoice.tax
            if taxes > 0, let government = government {
                government.increaseWallet(amount: incomeTax + transaction.invoice.tax, self.dataStore)
            }
            let moneyToReceive = (transaction.invoice.netValue - incomeTax).rounded(toPlaces: 0)
            if moneyToReceive > 0 {
                recipient.increaseWallet(amount: moneyToReceive, self.dataStore)
            }
            if !recipient.isSystemPlayer {
                self.archive(playerID: recipient.uuid, title: transaction.invoice.title, amount: transaction.invoice.netValue)
                if incomeTax > 0 {
                    self.archive(playerID: recipient.uuid, title: "Income tax (\((self.taxRates.incomeTax*100).rounded(toPlaces: 1))%) for \(transaction.invoice.title)", amount: -1 * incomeTax)
                }
            }
        }
        self.semaphore.signal()
    }
    
    func refundIncomeTax(transaction: FinancialTransaction, costs: Double) {
        
        guard !(SystemPlayer.allCases.map{ $0.uuid }.contains(transaction.recipientUUID)) else { return }
        guard costs > 0 else { return }
        let paidIncomeTax = (transaction.invoice.netValue * self.taxRates.incomeTax).rounded(toPlaces: 0)
        guard paidIncomeTax > 0 else { return }

        if let payer: Player = self.dataStore.find(uuid: transaction.recipientUUID) {
            
            var refund = 0.0

            if costs >= transaction.invoice.netValue {
                refund = paidIncomeTax
            } else {
                let incomeWithoutCosts = transaction.invoice.netValue - costs
                let taxAfterCosts = incomeWithoutCosts * self.taxRates.incomeTax
                refund = (paidIncomeTax - taxAfterCosts).rounded(toPlaces: 0)
            }
            if refund > 10 {
                payer.increaseWallet(amount: refund, self.dataStore)
                if let government: Player = self.dataStore.find(uuid: SystemPlayer.government.uuid) {
                    government.decreaseWallet(amount: refund, self.dataStore)
                }
                self.archive(playerID: payer.uuid, title: "Tax refund based on costs for \(transaction.invoice.title)", amount: refund)
            }
            
        }
        
    }
    
    private func archive(playerID: String, title: String, amount: Double) {
        
        let archive = CashFlow(month: self.time.month, title: title, playerID: playerID, amount: amount)
        self.dataStore.create(archive)
    }
}

fileprivate extension Player {
    func decreaseWallet(amount: Double, _ dataStore: DataStoreProvider) {
        let value = (self.wallet - amount).rounded(toPlaces: 0)
        dataStore.update(PlayerMutation(id: self.uuid, attributes: [.wallet(value)]))
    }
    
    func increaseWallet(amount: Double, _ dataStore: DataStoreProvider) {
        let value = (self.wallet + amount).rounded(toPlaces: 0)
        dataStore.update(PlayerMutation(id: self.uuid, attributes: [.wallet(value)]))
    }
}
