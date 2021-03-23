//
//  Storage.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class Storage: Codable {
    
    public static let shared = Storage()
    var players: [Player]
    
    private init() {
        self.players = [Player(id: "p1", login: "John"), Player(id: "p2", login: "Steve")]
    }
}
