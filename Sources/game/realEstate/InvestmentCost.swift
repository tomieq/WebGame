//
//  File.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class InvestmentCost {
    
    let investmentValue: Double
    let taxRate = TaxRates.investmentTax
    let tax: Double
    let total: Double
    
    init(investmentValue: Double) {
        self.investmentValue = investmentValue.rounded(toPlaces: 0)
        self.tax = (self.investmentValue * self.taxRate / 100).rounded(toPlaces: 0)
        self.total = (self.investmentValue + self.tax).rounded(toPlaces: 0)
    }
}
