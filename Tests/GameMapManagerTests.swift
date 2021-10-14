//
//  GameMapManagerTests.swift
//  
//
//  Created by Tomasz Kucharski on 14/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class GameMapManagerTests: XCTestCase {
    
    func test_initialization() {
        let map = GameMap(width: 2, height: 4, scale: 0.2)
        let mapManager = GameMapManager(map)
        XCTAssertEqual(map.height, mapManager.map.height)
        XCTAssertEqual(map.width, mapManager.map.width)
        XCTAssertEqual(map.scale, mapManager.map.scale)
    }
    
    func test_loadingMapFromString_simpleByWidth() {
        let map = GameMap(width: 2, height: 1, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = "s,s"
        mapManager.loadMapFrom(content: mapContent)
        XCTAssertEqual(map.tiles.count, 2)
        XCTAssertNotNil(map.getTile(address:MapPoint(x: 0, y: 0)))
        XCTAssertNotNil(map.getTile(address:MapPoint(x: 1, y: 0)))
    }
    
    func test_loadingMapFromString_simpleByHeight() {
        let map = GameMap(width: 1, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = "s\ns"
        mapManager.loadMapFrom(content: mapContent)
        XCTAssertEqual(map.tiles.count, 2)
        XCTAssertNotNil(map.getTile(address:MapPoint(x: 0, y: 0)))
        XCTAssertNotNil(map.getTile(address:MapPoint(x: 0, y: 1)))
    }
    
    func test_loadingMapFromString_exceedingMapWidth() {
        let map = GameMap(width: 2, height: 1, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = "s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        XCTAssertEqual(map.tiles.count, 2)
        XCTAssertNotNil(map.getTile(address:MapPoint(x: 0, y: 0)))
        XCTAssertNotNil(map.getTile(address:MapPoint(x: 1, y: 0)))
    }
    
    func test_loadingMapFromString_exceedingMapHeigh() {
        let map = GameMap(width: 1, height: 3, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = "s\ns\ns\ns"
        mapManager.loadMapFrom(content: mapContent)
        XCTAssertEqual(map.tiles.count, 3)
    }
    
    func test_loadingMapFromString_exceedingMapWidthAndHeigh() {
        let map = GameMap(width: 3, height: 3, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = "s,s,s,s,s\ns,s,s,s,s\ns,s,s,s,s\ns,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        XCTAssertEqual(map.tiles.count, 9)
    }
}
