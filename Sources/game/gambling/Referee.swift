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
    case didAlreadySentBribeOffer
    case refereeAlreadyTookMoney

    var description: String {
        switch self {
        case .bribeTooSmall:
            return "The referee is well paid and he will not risk his career for such small amount of money."
        case .matchNotFound:
            return "Problems with reaching the referee. He is too busy to talk with him."
        case .outOfTime:
            return "The match has finished. You are too late."
        case .betNotFound:
            return "Please make a bet first. Then you can talk to the referee."
        case .financialProblem(let error):
            return "Ups. You went to the meeting with empty wallet? \(error.description)"
        case .didAlreadySentBribeOffer:
            return "You have already sent offer and you can not do it twice"
        case .refereeAlreadyTookMoney:
            return "Referee is not interested any more."
        }
    }
}

protocol RefereeDelegate {
    var upcomingMatch: FootballMatch { get }
    var centralBank: CentralBank { get }
    func getBet(playerUUID: String) -> FootballBet?
    func notify(playerUUID: String, _ notification: UINotification)
}

class Referee {
    var delegate: RefereeDelegate?
    private var bribers: [String] = []

    func nextMatch() {
        self.bribers = []
    }

    func didAlreadyTryBribe(playerUUID: String) -> Bool {
        return self.bribers.contains(playerUUID)
    }

    func bribe(playerUUID: String, matchUUID: String, amount: Double) throws {
        if self.didAlreadyTryBribe(playerUUID: playerUUID) {
            throw RefereeError.didAlreadySentBribeOffer
        }

        self.bribers.append(playerUUID)

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

        if let expectedResult = match.result, bet.expectedResult != expectedResult {
            throw RefereeError.refereeAlreadyTookMoney
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
            delegate.notify(playerUUID: playerUUID, UINotification(text: "Messenger took cash from you and went to the meeting with \(match.referee). Looks like everything is on a good way.", level: .success, duration: 20, icon: .bribe))
        } catch let error as FinancialTransactionError {
            Logger.info("Referee", "RefereeError.financialProblem - \(error.description)")
            throw RefereeError.financialProblem(error)
        } catch {
        }
    }
}
