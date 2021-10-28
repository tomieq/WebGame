//
//  FootballMatch.swift
//  
//
//  Created by Tomasz Kucharski on 28/10/2021.
//

import Foundation

enum FootballMatchResult {
    case team1Won
    case team2Won
    case draw
}

class FootballMatch {
    let uuid: String
    let team1: String
    let team2: String
    let referee: String
    let team1WinsRatio: Double
    let team2WinsRatio: Double
    let drawRatio: Double
    var result: FootballMatchResult?
    var goals: (team1: Int, team2: Int)?
    
    var ratio: Double? {
        guard let result = self.result else { return nil }
        switch result {
        case .team1Won:
            return self.team1WinsRatio
        case .team2Won:
            return self.team2WinsRatio
        case .draw:
            return self.drawRatio
        }
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
        if self.result != nil { return }
        let goals = (team1: Int.random(in: (0...5)), team2: Int.random(in: (0...5)))
        if goals.team1 == goals.team2 {
            self.result = .draw
        }
        if goals.team1 > goals.team2 {
            self.result = .team1Won
        } else {
            self.result = .team2Won
        }
        self.goals = goals
        
    }
}
