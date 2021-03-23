//
//  TransactionCost.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class TransactionCost {
    let propertyValue: Double
    let taxRate = TaxRates.purchaseTax
    let tax: Double
    let fee: Double
    let total: Double
    
    init(propertyValue: Double) {
        self.propertyValue = propertyValue.rounded(toPlaces: 0)
        self.tax = (self.propertyValue * self.taxRate / 100).rounded(toPlaces: 0)
        self.fee = (self.propertyValue * 0.01).rounded(toPlaces: 0)
        self.total = (self.propertyValue + self.tax + self.fee).rounded(toPlaces: 0)
    }
}
