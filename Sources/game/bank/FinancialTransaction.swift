//
//  FinancialTransaction.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation

struct FinancialTransaction: Codable {
    let payerID: String
    let recipientID: String
    let invoice: Invoice
    let incomeTax: Double
    
    init(payerID: String, recipientID: String, invoice: Invoice) {
        self.payerID = payerID
        self.recipientID = recipientID
        self.invoice = invoice
        self.incomeTax = (invoice.netValue * TaxRates.incomeTax).rounded(toPlaces: 0)
    }
}
