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
    case canNotBetTwice
    
    var description: String {
        switch self {
        case .financialProblem(let finance):
            return finance.description
        case .outOfTime:
            return "Match already started. You cannot make a bet any more."
        case .canNotBetTwice:
            return "You have already made a bet. Can not bet twice on the same match."
        }
    }
}

protocol FootballBookieDelegate {
    func syncWalletChange(playerUUID: String)
    func notify(playerUUID: String, _ notification: UINotification)
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
        if (self.bets.contains{ $0.playerUUID == bet.playerUUID}) {
            throw MakeBetError.canNotBetTwice
        }
        let invoice = Invoice(title: "Footbal match bet", grossValue: bet.money, taxRate: 0)
        let transaction = FinancialTransaction(payerUUID: bet.playerUUID, recipientUUID: SystemPlayer.bookie.uuid, invoice: invoice)
        do {
            try self.centralBank.process(transaction, taxFree: true)
            self.bets.append(bet)
            self.delegate?.syncWalletChange(playerUUID: bet.playerUUID)
            func who() -> String {
                switch bet.expectedResult {
                case .draw:
                    return "draw"
                case .team1Won:
                    return self.currentMatch.team1
                case .team2Won:
                    return self.currentMatch.team2
                }
            }
            let txt = "Bookmaker: Thank you for playing with us! You have bet \(bet.money.money) on \(who())"
            self.delegate?.notify(playerUUID: bet.playerUUID, UINotification(text: txt, level: .success, duration: 10))
        } catch let error as FinancialTransactionError {
            throw MakeBetError.financialProblem(error)
        }
    }
    
    func nextMonth() {
        let match = self.currentMatch
        match.playMatch()
        let ratio = match.ratio ?? 1
        var winnerUUIDs: [String] = []
        var looserUUIDs: [String] = []
        
        for bet in self.bets {
            if bet.expectedResult == self.currentMatch.result {
                let money = bet.money * ratio
                let invoice = Invoice(title: "Money transfer from bookmaker. Revenue for the bet", grossValue: money, taxRate: 0)
                let transaction = FinancialTransaction(payerUUID: SystemPlayer.bookie.uuid, recipientUUID: bet.playerUUID, invoice: invoice)
                try? self.centralBank.process(transaction, taxFree: true)
                winnerUUIDs.append(bet.playerUUID)
            } else {
                looserUUIDs.append(bet.playerUUID)
            }
        }
        let results = "\(match.team1) <b>\(match.goals?.team1 ?? 0)</b> vs <b>\(match.goals?.team2 ?? 0)</b> \(match.team2)"
        let winnerMessage = "Bookmaker: We have match results!<br>\(results)<br>Your bet has brought you money! Congratulations!"
        let looserMessage = "Bookmaker: We have match results!<br>\(results)<br>Your bet has lost! You need to try again."
        for winnerUUID in winnerUUIDs.unique {
            self.delegate?.syncWalletChange(playerUUID: winnerUUID)
            self.delegate?.notify(playerUUID: winnerUUID, UINotification(text: winnerMessage, level: .success, duration: 10))
        }
        for looserUUID in looserUUIDs {
            self.delegate?.notify(playerUUID: looserUUID, UINotification(text: looserMessage, level: .warning, duration: 10))
        }
        self.lastMatch = self.currentMatch
        self.currentMatch = FootballMatch(team: self.localTeam)
        self.bets = []
    }
}
