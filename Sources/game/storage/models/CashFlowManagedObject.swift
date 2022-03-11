//
//  FinancialTransactionArchiveManagedObject.swift
//
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

class CashFlowManagedObject: Codable {
    let id: Int
    let uuid: String
    let month: Int
    let title: String
    let playerID: String
    let amount: Double

    init(_ archive: CashFlow) {
        self.id = Int(Date().timeIntervalSince1970)
        self.uuid = UUID().uuidString
        self.month = archive.month
        self.title = archive.title
        self.playerID = archive.playerID
        self.amount = archive.amount
    }
}
