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
    
    init(dataStore: DataStoreProvider, taxRates: TaxRates) {
        self.dataStore = dataStore
        self.taxRates = taxRates
    }

    func process(_ transaction: FinancialTransaction) throws {
        Logger.info("CentralBank", "New transaction \(transaction.toJSONString() ?? "")")
        
        guard transaction.invoice.total > 0 else { throw FinancialTransactionError.negativeTransactionValue }

        guard let payer = self.dataStore.find(uuid: transaction.payerID) else {
            throw FinancialTransactionError.payerNotFound
        }
        guard let recipient = self.dataStore.find(uuid: transaction.recipientID) else {
            throw FinancialTransactionError.recipientNotFound
        }
        let government = self.dataStore.getPlayer(type: .government)
        
        guard payer.wallet > transaction.invoice.total else {
            throw FinancialTransactionError.notEnoughMoney
        }
        
        // update payer's wallet
        self.pay(payer, transaction.invoice.total)

        if payer.type == .user {
            self.archive(playerID: payer.uuid, title: transaction.invoice.title, amount: -1 * transaction.invoice.total)
        }
        
        if recipient.uuid == government?.uuid, let government = government {
            self.receive(government, transaction.invoice.total)
        } else {
            // government takes income tax and VAT
            
            var incomeTax = (transaction.invoice.netValue * self.taxRates.incomeTax).rounded(toPlaces: 0)
            if incomeTax > transaction.invoice.netValue { incomeTax = transaction.invoice.netValue }
            let taxes = incomeTax + transaction.invoice.tax
            if taxes > 0, let government = government {
                receive(government, incomeTax + transaction.invoice.tax)
            }
            let moneyToReceive = (transaction.invoice.netValue - incomeTax).rounded(toPlaces: 0)
            if moneyToReceive > 0 {
                self.receive(recipient, moneyToReceive)
            }
            if recipient.type == .user {
                self.archive(playerID: recipient.uuid, title: transaction.invoice.title, amount: transaction.invoice.netValue)
                if incomeTax > 0 {
                    self.archive(playerID: recipient.uuid, title: "Income tax (\((self.taxRates.incomeTax*100).rounded(toPlaces: 1))%) for \(transaction.invoice.title)", amount: -1 * incomeTax)
                }
            }
        }
    }
    
    func refundIncomeTax(receiverID: String, transaction: FinancialTransaction, costs: Double) {
        
        guard costs > 0 else { return }
        let paidIncomeTax = (transaction.invoice.netValue * self.taxRates.incomeTax).rounded(toPlaces: 0)
        guard paidIncomeTax > 0 else { return }

        if let payer = self.dataStore.find(uuid: receiverID) {
            
            var refund = 0.0

            if costs >= transaction.invoice.netValue {
                refund = paidIncomeTax
            } else {
                let incomeWithoutCosts = transaction.invoice.netValue - costs
                let taxAfterCosts = incomeWithoutCosts * self.taxRates.incomeTax
                refund = (paidIncomeTax - taxAfterCosts).rounded(toPlaces: 0)
            }
            if refund > 10 {
                self.receive(payer, refund)
                if let government = self.dataStore.getPlayer(type: .government) {
                    self.pay(government, refund)
                }
                self.archive(playerID: payer.uuid, title: "Tax refund based on costs for \(transaction.invoice.title)", amount: refund)
            }
            
        }
        
    }
    
    private func pay(_ payer: Player, _ amount: Double) {
        let value = (payer.wallet - amount).rounded(toPlaces: 0)
        self.dataStore.update(PlayerMutation(id: payer.uuid, attributes: [.wallet(value)]))
    }
    
    private func receive(_ receiver: Player, _ amount: Double) {
        let value = (receiver.wallet + amount).rounded(toPlaces: 0)
        self.dataStore.update(PlayerMutation(id: receiver.uuid, attributes: [.wallet(value)]))
    }
    
    private func archive(playerID: String, title: String, amount: Double) {

        let monthIteration = Storage.shared.monthIteration
        
        let archive = CashFlow(month: monthIteration, title: title, playerID: playerID, amount: amount)
        self.dataStore.create(archive)
    }
}
