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
    @discardableResult func create(_ transaction: Land) -> String
    
    func find(uuid: String) -> Player?
    func find(address: MapPoint) -> Land?
    func getPlayer(type: PlayerType) -> Player?
    func getFinancialTransactions(userID: String) -> [CashFlow]
    
    func update(_ mutation: PlayerMutation)
    func update(_ mutation: LandMutation)

    func removePlayer(id: String)
    func removeLand(uuid: String)
}
