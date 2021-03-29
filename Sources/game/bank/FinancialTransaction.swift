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
    let feeRecipientID: String?
    let invoice: Invoice
    let incomeTax: Double
    var addIncomeTax: Bool = true
    
    init(payerID: String, recipientID: String, feeRecipientID: String? = nil, invoice: Invoice) {
        self.payerID = payerID
        self.recipientID = recipientID
        self.feeRecipientID = feeRecipientID
        self.invoice = invoice
        self.incomeTax = ((invoice.netValue * Double(TaxRates.incomeTax))/100).rounded(toPlaces: 0)
    }
}
