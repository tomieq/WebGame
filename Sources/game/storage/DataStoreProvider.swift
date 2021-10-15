//
//  DataStoreProvider.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

protocol DataStoreProvider {
    func createPlayer(_ player: PlayerCreateRequest) -> String
    func getPlayer(id: String) -> Player?
}
