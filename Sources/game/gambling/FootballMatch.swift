//
//  FootballMatch.swift
//  
//
//  Created by Tomasz Kucharski on 28/10/2021.
//

import Foundation

enum FootballMatchResult: String {
    case team1Win
    case team2Win
    case draw
}

typealias Goals = (team1: Int, team2: Int)

class FootballMatch {
    let uuid: String
    let team1: String
    let team2: String
    let referee: String
    let team1WinsRatio: Double
    let team2WinsRatio: Double
    let drawRatio: Double

    private var matchResult: FootballMatchResult?
    private var matchGoals: Goals?
    private var matchIsSuspected: Bool = false
    
    var result: FootballMatchResult? {
        self.matchResult
    }
    var goals: Goals? {
        self.matchGoals
    }
    var isSuspected: Bool {
        self.matchIsSuspected
    }
    
    var winRatio: Double? {
        guard let result = self.result else { return nil }
        return self.resultRatio(result)
    }
    
    init(team: String) {
        self.uuid = UUID().uuidString
        self.team1 = team
        self.team2 = RandomNameGenerator.getName()
        self.referee = RandomPersonGenerator.getName()
        self.team1WinsRatio = Double.random(in: (1.9...2.7))
        self.team2WinsRatio = Double.random(in: (1.9...2.7))
        self.drawRatio = Double.random(in: (3...5.7))
    }
    
    func playMatch() {
        guard self.matchResult == nil else {
            self.matchIsSuspected = true
            return
        }
        let goals = (team1: Int.random(in: (0...5)), team2: Int.random(in: (0...5)))
        self.setResult(goals: goals)
    }
    
    func resultRatio(_ result: FootballMatchResult) -> Double {
        switch result {
        case .team1Win:
            return self.team1WinsRatio
        case .team2Win:
            return self.team2WinsRatio
        case .draw:
            return self.drawRatio
        }
    }
    
    func setResult(goals: Goals) {
        guard self.matchResult == nil else { return }
        
        if goals.team1 == goals.team2 {
            self.matchResult = .draw
        } else if goals.team1 > goals.team2 {
            self.matchResult = .team1Win
        } else {
            self.matchResult = .team2Win
        }
        self.matchGoals = goals
    }
}
