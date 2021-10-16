//
//  FinancialTransactionArchive.swift
//  
//
//  Created by Tomasz Kucharski on 29/03/2021.
//

import Foundation

struct CashFlow: Codable {
    let uuid: String
    let month: Int
    let title: String
    let playerID: String
    let amount: Double

    init(uuid: String? = nil, month: Int, title: String, playerID: String, amount: Double) {
        self.uuid = uuid ?? ""
        self.month = month
        self.title = title
        self.playerID = playerID
        self.amount = amount
    }
    
    init(_ managedObject: CashFlowManagedObject) {
        self.uuid = managedObject.uuid
        self.month = managedObject.month
        self.title = managedObject.title
        self.playerID = managedObject.playerID
        self.amount = managedObject.amount
    }
}
