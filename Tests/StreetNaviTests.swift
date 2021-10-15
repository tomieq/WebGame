//
//  StreetNaviTests.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class StreetNaviTests: XCTestCase {

    func test_initializationWithEmptyMap() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let navi = StreetNavi(gameMap: map)
        XCTAssertEqual(map.width, navi.gameMap.width)
        XCTAssertEqual(map.height, navi.gameMap.height)
        XCTAssertEqual(map.scale, navi.gameMap.scale)
    }
}
