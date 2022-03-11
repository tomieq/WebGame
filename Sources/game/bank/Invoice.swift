//
//  Invoice.swift
//
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

struct Invoice: Codable {
    let title: String
    let netValue: Double
    let tax: Double
    let total: Double
    let taxRate: Double

    init(title: String, netValue: Double, taxRate: Double) {
        self.title = title
        self.netValue = netValue.rounded(toPlaces: 0)
        self.taxRate = taxRate
        self.tax = (self.netValue * self.taxRate).rounded(toPlaces: 0)
        self.total = (self.netValue + self.tax).rounded(toPlaces: 0)
    }

    init(title: String, grossValue: Double, taxRate: Double) {
        self.title = title
        self.netValue = (grossValue / (1.0 + taxRate)).rounded(toPlaces: 0)
        self.taxRate = taxRate
        self.tax = (self.netValue * self.taxRate).rounded(toPlaces: 0)
        self.total = (self.netValue + self.tax).rounded(toPlaces: 0)
    }
}
