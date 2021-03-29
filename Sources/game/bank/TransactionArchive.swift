//
//  TransactionArchive.swift
//  
//
//  Created by Tomasz Kucharski on 29/03/2021.
//

import Foundation

class TransactionArchive: Codable {
    let id: Int
    let monthIteration: Int
    let title: String
    let playerID: String
    let amount: Double
    
    init(id: Int, monthIteration: Int, title: String, playerID: String, amount: Double) {
        self.id = id
        self.monthIteration = monthIteration
        self.title = title
        self.playerID = playerID
        self.amount = amount
    }
}
