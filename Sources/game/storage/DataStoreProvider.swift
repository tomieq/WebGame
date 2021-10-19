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
    @discardableResult func create(_ transaction: Road) -> String
    
    func find(uuid: String) -> Player?
    func find(address: MapPoint) -> Land?
    func find(address: MapPoint) -> Road?
    func getFinancialTransactions(userID: String) -> [CashFlow]
    
    func getAll() -> [Land]
    func getAll() -> [Road]
    
    func update(_ mutation: PlayerMutation)
    func update(_ mutation: LandMutation)
    func update(_ mutation: RoadMutation)

    func removePlayer(id: String)
    func removeLand(uuid: String)
    func removeRoad(uuid: String)
}
