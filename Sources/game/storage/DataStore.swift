//
//  DataStore.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

protocol DataStoreProvider {
    func getPlayer(id: String) -> Player?
}

class DataStoreMemoryProvider: DataStoreProvider {
    private var players: [Player]
    init() {
        self.players = []
        for id in SystemPlayerID.allCases {
            self.players.append(Player(id: id.rawValue, login: id.login, type: .system, wallet: 0))
        }
        self.players.append(Player(id: "p1", login: "John Cash"))
        self.players.append(Player(id: "p2", login: "Steve Poor"))
    }
    
    func getPlayer(id: String) -> Player? {
        return self.players.first { $0.id == id }
    }
}

class DataStore {
    
    private static let memoryProvider = DataStoreMemoryProvider()
    
    static var provider: DataStoreProvider {
        return DataStore.memoryProvider
    }
}
