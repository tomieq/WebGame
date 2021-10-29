//
//  FinancialTransaction.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

enum FinancialTransactionType: Codable {
    case gambling
    case realEstateTrade
    case investments
    case services
    case incomeTaxFree
    case fine
}

struct FinancialTransaction: Codable {
    let payerUUID: String
    let recipientUUID: String
    let invoice: Invoice
    let type: FinancialTransactionType
    
    init(payerUUID: String, recipientUUID: String, invoice: Invoice, type: FinancialTransactionType) {
        self.payerUUID = payerUUID
        self.recipientUUID = recipientUUID
        self.invoice = invoice
        self.type = type
    }
}
