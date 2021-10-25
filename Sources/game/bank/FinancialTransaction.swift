//
//  FinancialTransaction.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

struct FinancialTransaction: Codable {
    let payerUUID: String
    let recipientUUID: String
    let invoice: Invoice
    
    init(payerUUID: String, recipientUUID: String, invoice: Invoice) {
        self.payerUUID = payerUUID
        self.recipientUUID = recipientUUID
        self.invoice = invoice
    }
}
