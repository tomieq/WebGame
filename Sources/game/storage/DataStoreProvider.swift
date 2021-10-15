//
//  DataStoreProvider.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

protocol DataStoreProvider {
    @discardableResult func createPlayer(_ player: PlayerCreateRequest) -> String
    func getPlayer(id: String) -> Player?
    func getPlayer(type: PlayerType) -> Player?
    func update(_ playerMutation: PlayerMutation)
    func removePlayer(id: String)
}
