//
//  DataStoreProvider.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

protocol DataStoreProvider {
    @discardableResult func create(_ player: Player) -> String
    func getPlayer(id: String) -> Player?
    func getPlayer(type: PlayerType) -> Player?
    func update(_ playerMutation: PlayerMutation)
    func removePlayer(id: String)
    @discardableResult func create(_ transaction: CashFlow) -> String
    func getFinancialTransactions(userID: String) -> [CashFlow]
}
