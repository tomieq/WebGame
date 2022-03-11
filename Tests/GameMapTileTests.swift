//
//  GameMapTileTests.swift
//
//
//  Created by Tomasz Kucharski on 14/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class GameMapTileTests: XCTestCase {
    func test_isStreet_localStreet() {
        let mapTile = GameMapTile(address: MapPoint(x: 5, y: 6), type: .street(type: .local(.localCross)))
        XCTAssertTrue(mapTile.isStreet())
    }

    func test_isStreet_mainStreet() {
        let mapTile = GameMapTile(address: MapPoint(x: 5, y: 6), type: .street(type: .main(.mainY)))
        XCTAssertTrue(mapTile.isStreet())
    }

    func test_isStreet_building() {
        let mapTile = GameMapTile(address: MapPoint(x: 5, y: 6), type: .building(size: 6, balcony: .none))
        XCTAssertFalse(mapTile.isStreet())
    }

    func test_isStreet_tree() {
        let mapTile = GameMapTile(address: MapPoint(x: 5, y: 6), type: .tree(type: 1))
        XCTAssertFalse(mapTile.isStreet())
    }

    func test_isBuilding_building() {
        let mapTile = GameMapTile(address: MapPoint(x: 5, y: 6), type: .building(size: 0, balcony: .none))
        XCTAssertTrue(mapTile.isBuilding())
    }

    func test_isBuilding_buildingUnderConstruction() {
        let mapTile = GameMapTile(address: MapPoint(x: 5, y: 6), type: .buildingUnderConstruction(size: 2))
        XCTAssertTrue(mapTile.isBuildingUnderConstruction())
    }

    func test_isBuilding_localStreet() {
        let mapTile = GameMapTile(address: MapPoint(x: 5, y: 6), type: .street(type: .local(.localDeadEndX1)))
        XCTAssertFalse(mapTile.isBuilding())
    }
}
