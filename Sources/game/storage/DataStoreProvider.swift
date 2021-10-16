//
//  DataStoreProvider.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

protocol DataStoreProvider {
    @discardableResult func create(_ player: Player) -> String
    @discardableResult func create(_ transaction: CashFlow) -> String
    
    func find(uuid: String) -> Player?
    func getPlayer(type: PlayerType) -> Player?
    func getFinancialTransactions(userID: String) -> [CashFlow]
    
    func update(_ playerMutation: PlayerMutation)
    func removePlayer(id: String)
}
