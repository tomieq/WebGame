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

struct FootballBetArchive {
    let match: FootballMatch
    let bets: [FootballBet]

    func getBet(playerUUID: String) -> FootballBet? {
        return self.bets.first{ $0.playerUUID == playerUUID }
    }
}

class FootballBookie {
    let localTeam: String
    var archiveCapacity = 5
    private var archive: [FootballBetArchive] = []
    private var match: FootballMatch
    private var bets: [FootballBet]
    let referee: Referee
    let centralBank: CentralBank
    var delegate: FootballBookieDelegate?

    var upcomingMatch: FootballMatch {
        self.match
    }

    var lastMonthMatch: FootballMatch? {
        self.archive.last?.match
    }

    init(centralBank: CentralBank) {
        self.localTeam = RandomNameGenerator.getName()
        self.match = FootballMatch(team: self.localTeam)
        self.referee = Referee()
        self.bets = []
        self.centralBank = centralBank

        self.referee.delegate = self
    }

    func makeBet(bet: FootballBet) throws {
        guard bet.matchUUID == self.match.uuid else {
            throw MakeBetError.outOfTime
        }
        if (self.bets.contains{ $0.playerUUID == bet.playerUUID }) {
            throw MakeBetError.canNotBetTwice
        }
        let invoice = Invoice(title: "Footbal match bet", grossValue: bet.money, taxRate: 0)
        let transaction = FinancialTransaction(payerUUID: bet.playerUUID, recipientUUID: SystemPlayer.bookie.uuid, invoice: invoice, type: .incomeTaxFree)
        do {
            try self.centralBank.process(transaction)
            self.bets.append(bet)
            self.delegate?.syncWalletChange(playerUUID: bet.playerUUID)

            func who() -> String {
                switch bet.expectedResult {
                case .draw:
                    return "draw"
                case .team1Win:
                    return self.match.team1
                case .team2Win:
                    return self.match.team2
                }
            }
            let txt = "Bookmaker: Thank you for playing with us! You have bet \(bet.money.money) on \(who())"
            self.delegate?.notify(playerUUID: bet.playerUUID, UINotification(text: txt, level: .success, duration: 10, icon: .betting))
        } catch let error as FinancialTransactionError {
            throw MakeBetError.financialProblem(error)
        }
    }

    func getBet(playerUUID: String) -> FootballBet? {
        return self.bets.first{ $0.playerUUID == playerUUID }
    }

    func getArchive() -> [FootballBetArchive] {
        return self.archive
    }

    func nextMonth() {
        self.match.playMatch()
        let winRatio = self.match.winRatio ?? 1
        print("Win ration is \(winRatio)")
        var winnerUUIDs: [String] = []
        var looserUUIDs: [String] = []

        for bet in self.bets {
            if bet.expectedResult == self.match.result {
                let money = bet.money * winRatio
                let invoice = Invoice(title: "Money transfer from bookmaker. Revenue for the bet", grossValue: money, taxRate: 0)
                let transaction = FinancialTransaction(payerUUID: SystemPlayer.bookie.uuid, recipientUUID: bet.playerUUID, invoice: invoice, type: .gambling)
                try? self.centralBank.process(transaction, checkWalletCapacity: false)
                self.centralBank.refundIncomeTax(transaction: transaction, costs: bet.money)
                winnerUUIDs.append(bet.playerUUID)
            } else {
                looserUUIDs.append(bet.playerUUID)
            }
        }
        let results = "\(self.match.team1) <b>\(self.match.goals?.team1 ?? 0)</b> vs <b>\(self.match.goals?.team2 ?? 0)</b> \(self.match.team2)"
        let winnerMessage = "Bookmaker: We have match results!<br>\(results)<br>Your bet has brought you money! Congratulations!"
        let looserMessage = "Bookmaker: We have match results!<br>\(results)<br>Your bet has lost! You need to try again."
        for winnerUUID in winnerUUIDs.unique {
            self.delegate?.syncWalletChange(playerUUID: winnerUUID)
            self.delegate?.notify(playerUUID: winnerUUID, UINotification(text: winnerMessage, level: .success, duration: 10, icon: .money))
        }
        for looserUUID in looserUUIDs {
            self.delegate?.notify(playerUUID: looserUUID, UINotification(text: looserMessage, level: .warning, duration: 10, icon: .redFlag))
        }

        self.archive.append(FootballBetArchive(match: self.match, bets: self.bets))
        if self.archive.count > self.archiveCapacity {
            self.archive.removeFirst()
        }

        self.match = FootballMatch(team: self.localTeam)
        self.bets = []
        self.referee.nextMatch()
    }
}

extension FootballBookie: RefereeDelegate {
    func notify(playerUUID: String, _ notification: UINotification) {
        self.delegate?.notify(playerUUID: playerUUID, notification)
    }
}
