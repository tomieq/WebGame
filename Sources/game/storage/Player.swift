//
//  Player.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

enum SystemPlayerID: String, CaseIterable {
    case government
    case bank
    case realEstateAgency
    
    var login: String {
        switch self {
        case .government:
            return "Government"
        case .bank:
            return "Central Bank"
        case .realEstateAgency:
            return "Real Estate Agency"
        }
    }
}

enum PlayerType: String, Codable {
    case user
    case system
}

class Player: Codable {
    let id: String
    let login: String
    let type: PlayerType
    var wallet: Double
    
    init(id: String, login: String, type: PlayerType = .user, wallet: Double = 10000000) {
        self.id = id
        self.login = login
        self.type = type
        self.wallet = wallet
    }
    
    func pay(_ invoice: Invoice) {
        self.wallet -= invoice.total
    }
    
    func receiveMoney(_ amount: Double) {
        self.wallet += amount.rounded(toPlaces: 0)
    }
}

class PlayerSession {
    
    let id: String
    let player: Player
    
    init(player: Player) {
        self.id = UUID().uuidString
        self.player = player
    }
}

extension PlayerSession: Equatable {
    
    static func == (lhs: PlayerSession, rhs: PlayerSession) -> Bool {
        lhs.id == rhs.id
    }
}

extension PlayerSession: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
