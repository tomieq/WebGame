//
//  Referee.swift
//  
//
//  Created by Tomasz Kucharski on 31/10/2021.
//

import Foundation

enum RefereeError: Error {
    case bribeTooSmall
}

class Referee {
    
    func bribe(playerUUID: String, matchUUID: String, amount: Double) throws {
        
        if amount < 10000 {
            throw RefereeError.bribeTooSmall
        }
    }
}
