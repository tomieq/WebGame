//
//  CentralBank.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

class CentralBank {
    public static let shared = CentralBank()
    
    private init() {
        
    }
    
    @discardableResult
    func process(_ transaction: FinancialTransaction) -> FinancialTransactionResult {
        let payer = Storage.shared.getPlayer(id: transaction.payerID)
        
        guard payer?.wallet ?? 0.0 > transaction.invoice.total else {
            return .failure(reason: "Not enough amount of money to finish the financial transaction")
        }
        
        Logger.info("CentralBank", "New transaction \(transaction.toJSONString() ?? "")")
        
        let recipient = Storage.shared.getPlayer(id: transaction.recipientID)
        let feeRecipient = Storage.shared.getPlayer(id: transaction.feeRecipientID ?? SystemPlayerID.government.rawValue)
        let government = Storage.shared.getPlayer(id: SystemPlayerID.government.rawValue)
        
        payer?.pay(transaction.invoice.total)
        if let payer = payer, payer.type == .user {
            self.archive(playerID: payer.id, title: transaction.invoice.title, amount: -1 * transaction.invoice.total)
        }
        government?.receiveMoney(transaction.invoice.tax)
        
        if transaction.addIncomeTax {
            recipient?.receiveMoney((transaction.invoice.netValue - transaction.incomeTax).rounded(toPlaces: 0))
            government?.receiveMoney(transaction.incomeTax)
            if let recipient = recipient, recipient.type == .user {
                self.archive(playerID: recipient.id, title: transaction.invoice.title, amount: transaction.invoice.netValue)
                self.archive(playerID: recipient.id, title: "Income tax (\(TaxRates.incomeTax)%) for \(transaction.invoice.title)", amount: -1 * transaction.incomeTax)
            }
        } else {
            recipient?.receiveMoney(transaction.invoice.netValue)
            if let recipient = recipient, recipient.type == .user {
                self.archive(playerID: recipient.id, title: transaction.invoice.title, amount: transaction.invoice.netValue)
            }
        }
        
        feeRecipient?.receiveMoney(transaction.invoice.fee)
        return .success
    }
    
    func taxRefund(receiverID: String, transaction: FinancialTransaction, costs: Double) {
        
        if transaction.addIncomeTax, let payer = Storage.shared.getPlayer(id: receiverID) {
            let paidTax = transaction.incomeTax
            let optimizedTax = ((transaction.invoice.netValue - costs)*Double(TaxRates.incomeTax)/100).rounded(toPlaces: 0)
            var refund: Double = 0
            if optimizedTax < 0 {
                refund = paidTax
            } else {
                refund = (paidTax - optimizedTax).rounded(toPlaces: 0)
            }
            payer.receiveMoney(refund)
            self.archive(playerID: payer.id, title: "Tax refund based on costs for \(transaction.invoice.title)", amount: refund)
        }
        
    }
    
    private func archive(playerID: String, title: String, amount: Double) {
        let transactionID = Storage.shared.bankTransactionCounter
        Storage.shared.bankTransactionCounter += 1
        let monthIteration = Storage.shared.monthIteration
        
        let archive = TransactionArchive(id: transactionID, monthIteration: monthIteration, title: title, playerID: playerID, amount: amount)
        Storage.shared.transactionArchive.append(archive)
    }
}

enum FinancialTransactionResult {
    case success
    case failure(reason: String)
}
