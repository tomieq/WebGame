//
//  GameTimeTests.swift
//  
//
//  Created by Tomasz Kucharski on 19/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class GameTimeTests: XCTestCase {

    func testNextMonth() {
        let time = GameTime()
        XCTAssertEqual(time.month, 0)
        time.nextMonth()
        XCTAssertEqual(time.month, 1)
    }
}
