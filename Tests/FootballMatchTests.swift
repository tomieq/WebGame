//
//  FootballMatchTests.swift
//
//
//  Created by Tomasz Kucharski on 28/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

class FootballMatchTests: XCTestCase {
    func test_teamIsSet() {
        let match = FootballMatch(team: "rangers")
        XCTAssertEqual(match.team1, "rangers")
    }

    func test_teamDoesNotChange() {
        let match = FootballMatch(team: "rangers")
        match.playMatch()
        match.playMatch()
        XCTAssertEqual(match.team1, "rangers")
    }

    func test_setGoals() {
        let match = FootballMatch(team: "rangers")
        let goals = (team1: 5, team2: 3)
        match.setResult(goals: goals, briberUUID: "gambler")
        match.playMatch()
        XCTAssertEqual(match.goals?.team1, goals.team1)
        XCTAssertEqual(match.goals?.team2, goals.team2)
    }

    func test_setIsSuspected() {
        let match = FootballMatch(team: "rangers")
        let goals = (team1: 5, team2: 3)
        match.setResult(goals: goals, briberUUID: "gambler")
        match.playMatch()
        XCTAssertEqual(match.isResultBribed, true)
    }

    func test_setIsNotSuspected() {
        let match = FootballMatch(team: "rangers")
        match.playMatch()
        XCTAssertEqual(match.isResultBribed, false)
    }
}
