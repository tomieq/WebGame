//
//  Player.swift
//
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

enum SystemPlayer: String, CaseIterable {
    case government
    case bank
    case realEstateAgency
    case investor
    case bookie

    var uuid: String {
        return self.rawValue
    }

    var login: String {
        switch self {
        case .government:
            return "Government"
        case .bank:
            return "Bank"
        case .realEstateAgency:
            return "Real Estate Agency"
        case .investor:
            return "Barren Wuffet"
        case .bookie:
            return "Bookmaker"
        }
    }
}

struct Player: Codable {
    let uuid: String
    let login: String
    let wallet: Double

    init(uuid: String? = nil, login: String, wallet: Double) {
        self.uuid = uuid ?? ""
        self.login = login
        self.wallet = wallet
    }

    init(_ managedObject: PlayerManagedObject) {
        self.uuid = managedObject.uuid
        self.login = managedObject.login
        self.wallet = managedObject.wallet
    }

    var isSystemPlayer: Bool {
        return SystemPlayer.allCases.map{ $0.uuid }.contains(self.uuid)
    }
}

struct PlayerMutation {
    let uuid: String
    let attributes: [PlayerMutation.Attribute]

    enum Attribute {
        case wallet(Double)
    }
}
