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
        
        let recipient = Storage.shared.getPlayer(id: transaction.recipientID)
        let feeRecipient = Storage.shared.getPlayer(id: transaction.feeRecipientID ?? SystemPlayerID.government.rawValue)
        let government = Storage.shared.getPlayer(id: SystemPlayerID.government.rawValue)
        
        payer?.pay(transaction.invoice.total)
        if let payer = payer, payer.type == .user {
            self.archive(playerID: payer.id, title: transaction.invoice.title, amount: -1 * transaction.invoice.total)
        }
        
        recipient?.receiveMoney(transaction.invoice.netValue)
        if let recipient = recipient, recipient.type == .user {
            self.archive(playerID: recipient.id, title: transaction.invoice.title, amount: transaction.invoice.total)
        }
        
        feeRecipient?.receiveMoney(transaction.invoice.fee)
        government?.receiveMoney(transaction.invoice.tax)
        
        Storage.shared.bankTransactionCounter += 1
        return .success
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
