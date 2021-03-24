//
//  FinancialTransaction.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class FinancialTransaction {
    
    let netValue: Double
    let tax: Double
    let total: Double
    let fee: Double
    let taxPercent: Int
    let feePercent: Int
    private let taxRate: Double
    private let feeRate: Double
    
    init(netValue: Double, taxPercent: Int, feePercent: Int = 0) {
        self.netValue = netValue.rounded(toPlaces: 0)
        self.taxPercent = taxPercent
        self.feePercent = feePercent
        self.taxRate = Double(self.taxPercent) / 100
        self.feeRate = Double(self.feePercent) / 100
        self.tax = (self.netValue * self.taxRate).rounded(toPlaces: 0)
        self.fee = (self.netValue * self.feeRate).rounded(toPlaces: 0)
        self.total = (self.netValue + self.tax + self.fee).rounded(toPlaces: 0)
    }
}
