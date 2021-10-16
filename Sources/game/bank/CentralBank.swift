//
//  CentralBank.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

class CentralBank {
    let dataStore: DataStoreProvider
    let taxRates: TaxRates
    
    init(dataStore: DataStoreProvider, taxRates: TaxRates) {
        self.dataStore = dataStore
        self.taxRates = taxRates
    }
    
    @discardableResult
    func process(_ transaction: FinancialTransaction) -> FinancialTransactionResult {
        Logger.info("CentralBank", "New transaction \(transaction.toJSONString() ?? "")")
        
        guard let payer = self.dataStore.find(uuid: transaction.payerID) else {
            return .failure(reason: "Payer not found!")
        }
        guard let recipient = self.dataStore.find(uuid: transaction.recipientID) else {
            return .failure(reason: "Recipient not found!")
        }
        let government = self.dataStore.getPlayer(type: .government)
        
        guard payer.wallet > transaction.invoice.total else {
            return .failure(reason: "Not enough amount of money to finish the financial transaction")
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
            let incomeTax = (transaction.invoice.netValue * self.taxRates.incomeTax).rounded(toPlaces: 0)
            if let government = government {
                receive(government, incomeTax + transaction.invoice.tax)
            }
            self.receive(recipient, (transaction.invoice.netValue - incomeTax).rounded(toPlaces: 0))
            if recipient.type == .user {
                self.archive(playerID: recipient.uuid, title: transaction.invoice.title, amount: transaction.invoice.netValue)
                self.archive(playerID: recipient.uuid, title: "Income tax (\((self.taxRates.incomeTax*100).rounded(toPlaces: 1))%) for \(transaction.invoice.title)", amount: -1 * incomeTax)
            }
        }
        
        return .success
    }
    
    func refundIncomeTax(receiverID: String, transaction: FinancialTransaction, costs: Double) {
        
        if let payer = self.dataStore.find(uuid: receiverID) {
            
            var refund = 0.0
            let paidIncomeTax = (transaction.invoice.netValue * self.taxRates.incomeTax).rounded(toPlaces: 0)

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

enum FinancialTransactionResult {
    case success
    case failure(reason: String)
}
