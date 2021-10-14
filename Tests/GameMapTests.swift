//
//  GameMapTests.swift
//  
//
//  Created by Tomasz Kucharski on 14/10/2021.
//

import Foundation
import Swifter
import XCTest
@testable import WebGameLib

final class GameMapTests: XCTestCase {
    
    func test_initialization() {
        let gameMap = GameMap(width: 20, height: 21, scale: 1)
        XCTAssertEqual(gameMap.width, 20)
        XCTAssertEqual(gameMap.height, 21)
        XCTAssertEqual(gameMap.scale, 1)
    }
}
