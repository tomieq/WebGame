//
//  CentralBank.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

class CentralBank {
    let dataStore: DataStoreProvider
    public static let shared = CentralBank()
    
    private init() {
        self.dataStore = DataStore.provider
    }
    
    @discardableResult
    func process(_ transaction: FinancialTransaction) -> FinancialTransactionResult {
        Logger.info("CentralBank", "New transaction \(transaction.toJSONString() ?? "")")
        
        let payer = self.dataStore.find(uuid: transaction.payerID)
        let recipient = self.dataStore.find(uuid: transaction.recipientID)
        let government = DataStore.provider.getPlayer(type: .government)
        
        guard payer?.wallet ?? 0.0 > transaction.invoice.total else {
            return .failure(reason: "Not enough amount of money to finish the financial transaction")
        }
        
        // update payer's wallet
        payer?.pay(transaction.invoice.total)
        if let payer = payer, payer.type == .user {
            self.archive(playerID: payer.uuid, title: transaction.invoice.title, amount: -1 * transaction.invoice.total)
        }
        
        if recipient?.uuid == government?.uuid {
            government?.receiveMoney(transaction.invoice.total)
        } else {
            // government takes income tax and VAT
            government?.receiveMoney(transaction.incomeTax + transaction.invoice.tax)
            recipient?.receiveMoney((transaction.invoice.netValue - transaction.incomeTax).rounded(toPlaces: 0))
            if let recipient = recipient, recipient.type == .user {
                self.archive(playerID: recipient.uuid, title: transaction.invoice.title, amount: transaction.invoice.netValue)
                self.archive(playerID: recipient.uuid, title: "Income tax (\((TaxRates.incomeTax*100).rounded(toPlaces: 1))%) for \(transaction.invoice.title)", amount: -1 * transaction.incomeTax)
            }
        }
        
        return .success
    }
    
    func refundIncomeTax(receiverID: String, transaction: FinancialTransaction, costs: Double) {
        
        if let payer = self.dataStore.find(uuid: receiverID) {
            
            var refund = 0.0
            let paidIncomeTax = transaction.incomeTax

            if costs >= transaction.invoice.netValue {
                refund = paidIncomeTax
            } else {
                let incomeWithoutCosts = transaction.invoice.netValue - costs
                let taxAfterCosts = incomeWithoutCosts * TaxRates.incomeTax
                refund = (paidIncomeTax - taxAfterCosts).rounded(toPlaces: 0)
            }
            if refund > 10 {
                let government = DataStore.provider.getPlayer(type: .government)
                payer.receiveMoney(refund)
                government?.pay(refund)
                self.archive(playerID: payer.uuid, title: "Tax refund based on costs for \(transaction.invoice.title)", amount: refund)
            }
            
        }
        
    }
    
    private func archive(playerID: String, title: String, amount: Double) {

        let monthIteration = Storage.shared.monthIteration
        
        let archive = CashFlow(month: monthIteration, title: title, playerID: playerID, amount: amount)
        DataStore.provider.create(archive)
    }
}

enum FinancialTransactionResult {
    case success
    case failure(reason: String)
}
