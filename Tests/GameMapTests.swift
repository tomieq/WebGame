//
//  GameMapTests.swift
//  
//
//  Created by Tomasz Kucharski on 14/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class GameMapTests: XCTestCase {
    
    func test_initialization() {
        let gameMap = GameMap(width: 20, height: 21, scale: 1)
        XCTAssertEqual(gameMap.width, 20)
        XCTAssertEqual(gameMap.height, 21)
        XCTAssertEqual(gameMap.scale, 1)
    }
    
    func test_settingTiles() {
        let gameMap = GameMap(width: 10, height: 10, scale: 1)
        let tile = GameMapTile(address: MapPoint(x: 3, y: 3), type: .building(size: 4))
        gameMap.setTiles([tile])
        XCTAssertEqual(gameMap.tiles.count, 1)
        XCTAssertEqual(gameMap.tiles.first?.address, tile.address)
    }
}
