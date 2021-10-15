//
//  DataStoreMemoryProvider.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

class DataStoreMemoryProvider: DataStoreProvider {
    private var players: [PlayerManagedObject]
    init() {
        self.players = []
        /*for id in SystemPlayerID.allCases {
            self.players.append(Player(id: id.rawValue, login: id.login, type: .system, wallet: 0))
        }
        self.players.append(Player(id: "p1", login: "John Cash"))
        self.players.append(Player(id: "p2", login: "Steve Poor"))
         */
    }
    
    func createPlayer(_ player: PlayerCreateRequest) -> String {
        let managedPlayer = PlayerManagedObject(player)
        self.players.append(managedPlayer)
        return managedPlayer.id
    }
    
    func getPlayer(id: String) -> Player? {
        return self.players.first { $0.id == id }.map{ Player($0) }
    }
}
