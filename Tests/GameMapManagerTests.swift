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
        /* it should be placed @(0,0) (1,0)
          --------
         ⎹ •  x → ⎸
         ⎹ y      ⎸
         ⎹ ↓      ⎸
          --------
          */
        XCTAssertEqual(map.tiles.count, 2)
        XCTAssertNotNil(map.getTile(address: MapPoint(x: 0, y: 0)))
        XCTAssertNotNil(map.getTile(address: MapPoint(x: 1, y: 0)))
    }

    func test_loadingMapFromString_simpleByHeight() {
        let map = GameMap(width: 1, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = "s\ns"
        mapManager.loadMapFrom(content: mapContent)
        /* it should be placed @(0,0) (0,1)
          --------
         ⎹ •  x → ⎸
         ⎹ y      ⎸
         ⎹ ↓      ⎸
          --------
          */
        XCTAssertEqual(map.tiles.count, 2)
        XCTAssertNotNil(map.getTile(address: MapPoint(x: 0, y: 0)))
        XCTAssertNotNil(map.getTile(address: MapPoint(x: 0, y: 1)))
    }

    func test_loadingMapFromString_exceedingMapWidth() {
        let map = GameMap(width: 2, height: 1, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = "s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        XCTAssertEqual(map.tiles.count, 2)
        XCTAssertNotNil(map.getTile(address: MapPoint(x: 0, y: 0)))
        XCTAssertNotNil(map.getTile(address: MapPoint(x: 1, y: 0)))
        XCTAssertNil(map.getTile(address: MapPoint(x: 2, y: 0)))
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

    func test_localStreetCurveBottomEvaluation() {
        let map = GameMap(width: 3, height: 3, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = "s,s,\n ,s"
        mapManager.loadMapFrom(content: mapContent)
        /*
          --------
         ⎹ •  x → ⎸
         ⎹ y      ⎸
         ⎹ ↓      ⎸
          --------

          (0,0)→  (1,0)↴
                  (1,1)↓
          */
        XCTAssertEqual(map.tiles.count, 3)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 0, y: 0))?.type, TileType.street(type: .local(.localDeadEndX1)))
        XCTAssertEqual(map.getTile(address: MapPoint(x: 1, y: 0))?.type, TileType.street(type: .local(.localCurveBottom)))
        XCTAssertEqual(map.getTile(address: MapPoint(x: 1, y: 1))?.type, TileType.street(type: .local(.localDeadEndY2)))
    }

    func test_localStreetCurveLeftEvaluation() {
        let map = GameMap(width: 3, height: 3, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = " ,s,\ns,s"
        mapManager.loadMapFrom(content: mapContent)
        /*
          --------
         ⎹ •  x → ⎸
         ⎹ y      ⎸
         ⎹ ↓      ⎸
          --------

                  (1,0)↓
           (0,1)← (1,1)↲
          */
        XCTAssertEqual(map.tiles.count, 3)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 1, y: 0))?.type, TileType.street(type: .local(.localDeadEndY1)))
        XCTAssertEqual(map.getTile(address: MapPoint(x: 1, y: 1))?.type, TileType.street(type: .local(.localCurveLeft)))
        XCTAssertEqual(map.getTile(address: MapPoint(x: 0, y: 1))?.type, TileType.street(type: .local(.localDeadEndX1)))
    }

    func test_addLocalStreetEvaluation() {
        let map = GameMap(width: 3, height: 3, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = " ,s,\ns,s"
        mapManager.loadMapFrom(content: mapContent)
        /*
          --------
         ⎹ •  x → ⎸
         ⎹ y      ⎸
         ⎹ ↓      ⎸
          --------

                  (1,0)↓
           (0,1)← (1,1)↲
          */
        XCTAssertEqual(map.tiles.count, 3)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 1, y: 1))?.type, TileType.street(type: .local(.localCurveLeft)))
        mapManager.addStreet(address: MapPoint(x: 2, y: 1))
        XCTAssertEqual(map.tiles.count, 4)
        XCTAssertEqual(map.getTile(address: MapPoint(x: 1, y: 1))?.type, TileType.street(type: .local(.localXIntersection1)))
        XCTAssertEqual(map.getTile(address: MapPoint(x: 2, y: 1))?.type, TileType.street(type: .local(.localDeadEndX2)))
    }

    func test_calculatingOccupiedSpace() {
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)
        let mapContent = "s,s,s,s,s"
        mapManager.loadMapFrom(content: mapContent)
        XCTAssertEqual(mapManager.occupiedSpaceOnMap(), 0.05)
    }
}
