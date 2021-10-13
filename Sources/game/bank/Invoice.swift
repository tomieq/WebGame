//
//  Invoice.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class Invoice: Codable {
    
    let title: String
    let netValue: Double
    let tax: Double
    let total: Double
    let fee: Double
    let taxPercent: Int
    let feePercent: Int
    private let taxRate: Double
    private let feeRate: Double
    
    init(title: String, netValue: Double, taxRate: Double, feeRate: Double = 0) {
        self.title = title
        self.netValue = netValue.rounded(toPlaces: 0)
        self.taxPercent = Int(taxRate*100)
        self.feePercent = Int(feeRate*100)
        self.taxRate = taxRate
        self.feeRate = feeRate
        self.tax = (self.netValue * self.taxRate).rounded(toPlaces: 0)
        self.fee = (self.netValue * self.feeRate).rounded(toPlaces: 0)
        self.total = (self.netValue + self.tax + self.fee).rounded(toPlaces: 0)
    }
}
