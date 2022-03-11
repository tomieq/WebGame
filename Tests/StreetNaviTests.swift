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

    func test_findNearestStreetPoint_noStreet() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = "s,s,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        XCTAssertNil(navi.findNearestStreetPoint(for: MapPoint(x: 3, y: 2)))
    }

    func test_findNearestStreetPoint_atNorth() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = "s,s,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        XCTAssertEqual(navi.findNearestStreetPoint(for: MapPoint(x: 3, y: 1)), MapPoint(x: 3, y: 0))
    }

    func test_findNearestStreetPoint_atSouth() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = "\ns,s,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        XCTAssertEqual(navi.findNearestStreetPoint(for: MapPoint(x: 4, y: 0)), MapPoint(x: 4, y: 1))
    }

    func test_findNearestStreetPoint_atWest() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = "\ns\ns\ns\ns\ns\ns"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        XCTAssertEqual(navi.findNearestStreetPoint(for: MapPoint(x: 1, y: 3)), MapPoint(x: 0, y: 3))
    }

    func test_findNearestStreetPoint_atEast() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = "\n ,s\n ,s\n ,s\n ,s\n ,s\n ,s"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        XCTAssertEqual(navi.findNearestStreetPoint(for: MapPoint(x: 0, y: 2)), MapPoint(x: 1, y: 2))
    }

    func test_findNearestStreetPoint_diagonalTopLeft() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = "s,s,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        XCTAssertEqual(navi.findNearestStreetPoint(for: MapPoint(x: 6, y: 1)), MapPoint(x: 5, y: 0))
    }

    func test_findNearestStreetPoint_diagonalTopRight() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = " ,s,s,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        XCTAssertEqual(navi.findNearestStreetPoint(for: MapPoint(x: 0, y: 1)), MapPoint(x: 1, y: 0))
    }

    func test_findNearestStreetPoint_diagonalBottomLeft() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = "\ns,s,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        XCTAssertEqual(navi.findNearestStreetPoint(for: MapPoint(x: 6, y: 0)), MapPoint(x: 5, y: 1))
    }

    func test_findNearestStreetPoint_diagonalBottomRight() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = "\n ,s,s,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        XCTAssertEqual(navi.findNearestStreetPoint(for: MapPoint(x: 0, y: 0)), MapPoint(x: 1, y: 1))
    }

    func test_routePoints_startNotOnStreet() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = " ,s,s,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        let routePoints = navi.routePoints(from: MapPoint(x: 0, y: 0), to: MapPoint(x: 5, y: 0))
        XCTAssertNil(routePoints)
    }

    func test_routePoints_straightHorizontalLine() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = "s,s,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        let routePoints = navi.routePoints(from: MapPoint(x: 0, y: 0), to: MapPoint(x: 5, y: 0))
        XCTAssertNotNil(routePoints)
        // this route should contain only 2 points
        XCTAssertEqual(routePoints?.count, 2)
        XCTAssertEqual(routePoints?.first, MapPoint(x: 0, y: 0))
        XCTAssertEqual(routePoints?.last, MapPoint(x: 5, y: 0))
    }

    func test_routePoints_straightVerticalLine() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = """
                                    s
                                    s
                                    s
                                    s
                                    s
                                    s
        """
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        let routePoints = navi.routePoints(from: MapPoint(x: 0, y: 0), to: MapPoint(x: 0, y: 5))
        XCTAssertNotNil(routePoints)
        // this route should contain only 2 points
        XCTAssertEqual(routePoints?.count, 2)
        XCTAssertEqual(routePoints?.first, MapPoint(x: 0, y: 0))
        XCTAssertEqual(routePoints?.last, MapPoint(x: 0, y: 5))
    }

    func test_routePoints_oneBend() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = """
                                    s,s,s,s,s,s
                                    s
                                    s
                                    s
                                    s
                                    s
        """
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        let routePoints = navi.routePoints(from: MapPoint(x: 0, y: 5), to: MapPoint(x: 5, y: 0))
        XCTAssertNotNil(routePoints)
        // this route should contain 3 points
        XCTAssertEqual(routePoints?.count, 3)
        XCTAssertEqual(routePoints?[0], MapPoint(x: 0, y: 5))
        XCTAssertEqual(routePoints?[1], MapPoint(x: 0, y: 0))
        XCTAssertEqual(routePoints?[2], MapPoint(x: 5, y: 0))
    }

    func test_routePoints_twoBends() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = """
                                    s,s,s,s,s
                                    s, , , ,s
                                    s, , , ,s
                                    s, , , ,s
                                    s, , , ,s
                                    s, , , ,s
        """
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        let routePoints = navi.routePoints(from: MapPoint(x: 0, y: 5), to: MapPoint(x: 4, y: 5))
        XCTAssertNotNil(routePoints)
        // this route should contain 3 points
        XCTAssertEqual(routePoints?.count, 4)
        XCTAssertEqual(routePoints?[0], MapPoint(x: 0, y: 5))
        XCTAssertEqual(routePoints?[1], MapPoint(x: 0, y: 0))
        XCTAssertEqual(routePoints?[2], MapPoint(x: 4, y: 0))
        XCTAssertEqual(routePoints?[3], MapPoint(x: 4, y: 5))
    }

    func test_routePoints_reloadMapShorterWay() {
        let map = GameMap(width: 10, height: 10, scale: 0.4)
        let mapManager = GameMapManager(map)
        let mapContent = """
                                    s,s,s,s,s,s
                                    s, ,s
                                    s, ,s
                                    s, ,s
                                    s, ,s
                                    s, ,s
        """
        mapManager.loadMapFrom(content: mapContent)
        let navi = StreetNavi(gameMap: map)
        var routePoints = navi.routePoints(from: MapPoint(x: 0, y: 5), to: MapPoint(x: 2, y: 5))
        XCTAssertNotNil(routePoints)
        // this route should contain 3 points
        XCTAssertEqual(routePoints?.count, 4)
        XCTAssertEqual(routePoints?[0], MapPoint(x: 0, y: 5))
        XCTAssertEqual(routePoints?[1], MapPoint(x: 0, y: 0))
        XCTAssertEqual(routePoints?[2], MapPoint(x: 2, y: 0))
        XCTAssertEqual(routePoints?[3], MapPoint(x: 2, y: 5))

        mapManager.addStreet(address: MapPoint(x: 1, y: 3))
        navi.reload()
        // now navi should return shorter way
        routePoints = navi.routePoints(from: MapPoint(x: 0, y: 5), to: MapPoint(x: 2, y: 5))
        XCTAssertEqual(routePoints?.count, 4)
        XCTAssertEqual(routePoints?[0], MapPoint(x: 0, y: 5))
        XCTAssertEqual(routePoints?[1], MapPoint(x: 0, y: 3))
        XCTAssertEqual(routePoints?[2], MapPoint(x: 2, y: 3))
        XCTAssertEqual(routePoints?[3], MapPoint(x: 2, y: 5))
    }
}
