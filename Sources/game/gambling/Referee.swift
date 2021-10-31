//
//  Referee.swift
//  
//
//  Created by Tomasz Kucharski on 31/10/2021.
//

import Foundation

enum RefereeError: Error, Equatable {
    case bribeTooSmall
    case matchNotFound
    case outOfTime
    case betNotFound
    case financialProblem(FinancialTransactionError)
}

protocol RefereeDelegate {
    var upcomingMatch: FootballMatch { get }
    var centralBank: CentralBank { get }
    func getBet(playerUUID: String) -> FootballBet?
}

class Referee {
    var delegate: RefereeDelegate?
    
    func bribe(playerUUID: String, matchUUID: String, amount: Double) throws {
        
        if amount < 10000 {
            Logger.info("Referee", "RefereeError.bribeTooSmall \(amount)")
            throw RefereeError.bribeTooSmall
        }
        
        guard let delegate = self.delegate, let match = self.delegate?.upcomingMatch else {
            Logger.info("Referee", "RefereeError.matchNotFound")
            throw RefereeError.matchNotFound
        }
        
        guard match.uuid == matchUUID else {
            Logger.info("Referee", "RefereeError.outOfTime")
            throw RefereeError.outOfTime
        }
        
        guard let bet = delegate.getBet(playerUUID: playerUUID) else {
            Logger.info("Referee", "RefereeError.betNotFound")
            throw RefereeError.betNotFound
        }
        
        let invoice = Invoice(title: "Gift for \(match.referee)", grossValue: amount, taxRate: 0)
        let transaction = FinancialTransaction(payerUUID: playerUUID, recipientUUID: SystemPlayer.bookie.uuid, invoice: invoice, type: .incomeTaxFree)
        do {
            try delegate.centralBank.process(transaction)
            switch bet.expectedResult {
                
            case .team1Win:
                match.setResult(goals: (Int.random(in: (5...8)), Int.random(in: (0...4))), briberUUID: playerUUID)
            case .team2Win:
                match.setResult(goals: (Int.random(in: (0...4)), Int.random(in: (5...8))), briberUUID: playerUUID)
            case .draw:
                let goal = Int.random(in: (0...4))
                match.setResult(goals: (goal, goal), briberUUID: playerUUID)
            }
        } catch let error as FinancialTransactionError {
            Logger.info("Referee", "RefereeError.financialProblem - \(error.description)")
            throw RefereeError.financialProblem(error)
        } catch {
            
        }
    }
}
