//
//  FinancialTransactionArchive.swift
//  
//
//  Created by Tomasz Kucharski on 29/03/2021.
//

import Foundation

class FinancialTransactionArchive: Codable {
    let id: Int
    let month: Int
    let title: String
    let playerID: String
    let amount: Double
    
    init(id: Int, month: Int, title: String, playerID: String, amount: Double) {
        self.id = id
        self.month = month
        self.title = title
        self.playerID = playerID
        self.amount = amount
    }
}
