//
//  FootballBookie.swift
//  
//
//  Created by Tomasz Kucharski on 28/10/2021.
//

import Foundation

struct FootballBet {
    let matchUUID: String
    let playerUUID: String
    let money: Double
    let expectedResult: FootballMatchResult
}

enum MakeBetError: Error, Equatable {
    case financialProblem(FinancialTransactionError)
    case outOfTime
    
    var description: String {
        switch self {
        case .financialProblem(let finance):
            return finance.description
        case .outOfTime:
            return "Match already started. You cannot make a bet any more."
        }
    }
}

protocol FootballBookieDelegate {
    func syncWalletChange(playerUUID: String)
}

class FootballBookie {
    let localTeam: String
    private var currentMatch: FootballMatch
    private var lastMatch: FootballMatch?
    private var bets: [FootballBet]
    let centralBank: CentralBank
    var delegate: FootballBookieDelegate?
    
    var upcomingMatch: FootballMatch {
        self.currentMatch
    }
    
    var lastMonthMatch: FootballMatch? {
        self.lastMatch
    }
    
    init(centralBank: CentralBank) {
        self.localTeam = RandomNameGenerator.getName()
        self.currentMatch = FootballMatch(team: self.localTeam)
        self.bets = []
        self.centralBank = centralBank
    }
    
    func makeBet(bet: FootballBet) throws {
        
        guard bet.matchUUID == self.upcomingMatch.uuid else {
            throw MakeBetError.outOfTime
        }
        let invoice = Invoice(title: "Footbal match bet", grossValue: bet.money, taxRate: 0)
        let transaction = FinancialTransaction(payerUUID: bet.playerUUID, recipientUUID: SystemPlayer.bookie.uuid, invoice: invoice)
        do {
            try self.centralBank.process(transaction, taxFree: true)
            self.bets.append(bet)
        } catch let error as FinancialTransactionError {
            throw MakeBetError.financialProblem(error)
        }
    }
    
    func nextMonth() {
        self.currentMatch.playMatch()
        let ratio = self.currentMatch.ratio ?? 1
        var winnerUUIDs: [String] = []
        for bet in self.bets {
            if bet.expectedResult == self.currentMatch.result {
                let money = bet.money * ratio
                let invoice = Invoice(title: "Football bet win!", grossValue: money, taxRate: 0)
                let transaction = FinancialTransaction(payerUUID: SystemPlayer.bookie.uuid, recipientUUID: bet.playerUUID, invoice: invoice)
                try? self.centralBank.process(transaction, taxFree: true)
                winnerUUIDs.append(bet.playerUUID)
            }
        }
        for winnerUUID in winnerUUIDs.unique {
            self.delegate?.syncWalletChange(playerUUID: winnerUUID)
        }
        self.lastMatch = self.currentMatch
        self.currentMatch = FootballMatch(team: self.localTeam)
        self.bets = []
    }
}
