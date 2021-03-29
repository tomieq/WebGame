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
        
        payer?.pay(transaction.invoice)
        recipient?.receiveMoney(transaction.invoice.netValue)
        feeRecipient?.receiveMoney(transaction.invoice.fee)
        government?.receiveMoney(transaction.invoice.tax)
        return .success
    }
}

enum FinancialTransactionResult {
    case success
    case failure(reason: String)
}
