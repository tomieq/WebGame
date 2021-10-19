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
    private var lands: [LandManagedObject]
    init() {
        self.players = []
        self.transactions = []
        self.lands = []
    }
    
    @discardableResult
    func create(_ player: Player) -> String {
        let managedPlayer = PlayerManagedObject(player)
        self.players.append(managedPlayer)
        return managedPlayer.uuid
    }
    
    func find(uuid: String) -> Player? {
        return self.players.first { $0.uuid == uuid }.map{ Player($0) }
    }
    
    func getPlayer(type: PlayerType) -> Player? {
        return self.players.first { $0.type == type }.map{ Player($0) }
    }
    
    func removePlayer(id: String) {
        self.players.removeAll{ $0.uuid == id}
    }

    func update(_ mutation: PlayerMutation) {
        guard let managedPlayer = (self.players.first{ $0.uuid == mutation.id }) else { return }
        for attribute in mutation.attributes {
            switch attribute {
                
            case .wallet(let value):
                managedPlayer.wallet = value
            }
        }
    }
    
    @discardableResult func create(_ transaction: CashFlow) -> String {
        let managedObject = CashFlowManagedObject(transaction)
        self.transactions.append(managedObject)
        return managedObject.uuid
    }
    
    func getFinancialTransactions(userID: String) -> [CashFlow] {
        self.transactions.filter{ $0.playerID == userID }.sorted { $0.id > $1.id }.map{ CashFlow($0)}
    }
    
    
    @discardableResult
    func create(_ land: Land) -> String {
        let managedObject = LandManagedObject(land)
        self.lands.append(managedObject)
        return managedObject.uuid
    }
    
    func find(address: MapPoint) -> Land? {
        return self.lands.first{ $0.x == address.x && $0.y == address.y }.map { Land($0) }
    }
    
    func getAll() -> [Land] {
        return self.lands.map { Land($0) }
    }
    
    func removeLand(uuid: String) {
        self.lands.removeAll{ $0.uuid == uuid }
    }
    
    
    func update(_ mutation: LandMutation) {
        guard let land = (self.lands.first{ $0.uuid == mutation.uuid }) else { return }
        for attribute in mutation.attributes {
            switch attribute {
                
            case .isUnderConstruction(let value):
                land.isUnderConstruction = value
            case .constructionFinishMonth(let value):
                land.constructionFinishMonth = value
            case .ownerUUID(let value):
                land.ownerUUID = value
            case .purchaseNetValue(let value):
                land.purchaseNetValue = value
            }
        }
    }
}
