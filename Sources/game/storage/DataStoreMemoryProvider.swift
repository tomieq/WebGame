//
//  DataStoreMemoryProvider.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

class DataStoreMemoryProvider: DataStoreProvider {
    private var players: [PlayerManagedObject]
    private var transactions: [CashFlowManagedObject]
    init() {
        self.players = []
        self.transactions = []
    }
    
    func createPlayer(_ player: Player) -> String {
        let managedPlayer = PlayerManagedObject(player)
        self.players.append(managedPlayer)
        return managedPlayer.uuid
    }
    
    func getPlayer(id: String) -> Player? {
        return self.players.first { $0.uuid == id }.map{ Player($0) }
    }
    
    func getPlayer(type: PlayerType) -> Player? {
        return self.players.first { $0.type == type }.map{ Player($0) }
    }
    
    func removePlayer(id: String) {
        self.players.removeAll{ $0.uuid == id}
    }

    func update(_ playerMutation: PlayerMutation) {
        guard let managedPlayer = (self.players.first{ $0.uuid == playerMutation.id }) else { return }
        for attribute in playerMutation.attributes {
            switch attribute {
                
            case .wallet(let value):
                managedPlayer.wallet = value
            }
        }
    }
    
    @discardableResult func createTransactionArchive(_ transaction: CashFlow) -> String {
        let managedObject = CashFlowManagedObject(transaction)
        self.transactions.append(managedObject)
        return managedObject.uuid
    }
    
    func getFinancialTransactions(userID: String) -> [CashFlow] {
        self.transactions.filter{ $0.playerID == userID }.sorted { $0.id > $1.id }.map{ CashFlow($0)}
    }
}
