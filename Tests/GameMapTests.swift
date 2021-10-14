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
    
    func test_gettingTiles_existing() {
        let gameMap = GameMap(width: 30, height: 30, scale: 0.5)
        let tile = GameMapTile(address: MapPoint(x: 2, y: 8), type: .building(size: 4))
        gameMap.setTiles([tile])
        
        let receivedTile = gameMap.getTile(address: MapPoint(x: 2, y: 8))
        XCTAssertNotNil(receivedTile)
        XCTAssertEqual(receivedTile?.address, tile.address)
        XCTAssertEqual(receivedTile?.type.image.path, tile.type.image.path)
    }
    
    func test_gettingTiles_nonExisting() {
        let gameMap = GameMap(width: 30, height: 30, scale: 0.5)
        let tile = GameMapTile(address: MapPoint(x: 2, y: 8), type: .building(size: 4))
        gameMap.setTiles([tile])
        
        let receivedTile = gameMap.getTile(address: MapPoint(x: 3, y: 8))
        XCTAssertNil(receivedTile)
    }
    
    func test_replaceTile() {
        let gameMap = GameMap(width: 5, height: 5, scale: 0.8)
        let tile = GameMapTile(address: MapPoint(x: 2, y: 8), type: .buildingUnderConstruction(size: 3))
        gameMap.setTiles([tile])
        let replacedTile = GameMapTile(address: MapPoint(x: 2, y: 8), type: .street(type: .local(.localCurveBottom)))
        gameMap.replaceTile(tile: replacedTile)
        XCTAssertEqual(gameMap.tiles.count, 1)
        let receivedTile = gameMap.getTile(address: MapPoint(x: 2, y: 8))
        XCTAssertEqual(receivedTile?.address, tile.address)
        XCTAssertEqual(receivedTile?.type.image.path, replacedTile.type.image.path)
    }
    
    func test_isAddressOnMap_within() {
        let gameMap = GameMap(width: 10, height: 10, scale: 1)
        XCTAssertTrue(gameMap.isAddressOnMap(MapPoint(x: 0, y: 0)), "0,0")
        XCTAssertTrue(gameMap.isAddressOnMap(MapPoint(x: 9, y: 9)), "9,9")
        XCTAssertTrue(gameMap.isAddressOnMap(MapPoint(x: 0, y: 9)), "0,9")
        XCTAssertTrue(gameMap.isAddressOnMap(MapPoint(x: 9, y: 0)), "9,0")
        XCTAssertTrue(gameMap.isAddressOnMap(MapPoint(x: 3, y: 4)), "3,4")
        XCTAssertTrue(gameMap.isAddressOnMap(MapPoint(x: 8, y: 2)), "8,2")
    }
    
    func test_isAddressOnMap_outside() {
        let gameMap = GameMap(width: 10, height: 10, scale: 1)
        XCTAssertFalse(gameMap.isAddressOnMap(MapPoint(x: -1, y: 0)), "-1,0")
        XCTAssertFalse(gameMap.isAddressOnMap(MapPoint(x: 0, y: -1)), "0,-1")
        XCTAssertFalse(gameMap.isAddressOnMap(MapPoint(x: -10, y: 10)), "-10,10")
        XCTAssertFalse(gameMap.isAddressOnMap(MapPoint(x: 10, y: 10)), "10,10")
        XCTAssertFalse(gameMap.isAddressOnMap(MapPoint(x: 2, y: 10)), "2,10")
        XCTAssertFalse(gameMap.isAddressOnMap(MapPoint(x: 10, y: 2)), "10,2")
        XCTAssertFalse(gameMap.isAddressOnMap(MapPoint(x: 15, y: 21)), "15,21")
    }
    
    func test_getNeighbourAddresses_pointOutsideMap() {
        let gameMap = GameMap(width: 10, height: 10, scale: 1)
        let mapPints = gameMap.getNeighbourAddresses(to: MapPoint(x: 12, y: 2), radius: 2)
        XCTAssertEqual(mapPints.count, 0)
    }
    
    func test_getNeighbourAddresses_negativeRadius() {
        let gameMap = GameMap(width: 10, height: 10, scale: 1)
        let mapPints = gameMap.getNeighbourAddresses(to: MapPoint(x: 2, y: 2), radius: -2)
        XCTAssertEqual(mapPints.count, 0)
    }
    
    func test_getNeighbourAddresses_zeroRadius() {
        let gameMap = GameMap(width: 10, height: 10, scale: 1)
        let mapPints = gameMap.getNeighbourAddresses(to: MapPoint(x: 2, y: 2), radius: 0)
        XCTAssertEqual(mapPints.count, 0)
    }
    
    func test_getNeighbourAddresses_fromMapCentre_radius1() {
        let gameMap = GameMap(width: 10, height: 10, scale: 1)
        let mapPints = gameMap.getNeighbourAddresses(to: MapPoint(x: 2, y: 2), radius: 1)
        XCTAssertEqual(mapPints.count, 8)
        /*
         (3,1) | (3,2) | (3,3)
         ------|-------|------
         (2,1) |   P   | (2,3)
         ------|-------|------
         (1,1) | (1,2) | (1,3)
         */
        XCTAssertTrue(mapPints.contains(MapPoint(x: 1, y: 1)), "1,1")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 1, y: 2)), "1,2")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 1, y: 3)), "1,3")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 2, y: 1)), "2,1")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 2, y: 3)), "2,3")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 3, y: 1)), "3,1")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 3, y: 2)), "3,2")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 3, y: 3)), "3,3")
    }
    
    func test_getNeighbourAddresses_atLeftEdge_radius1() {
        let gameMap = GameMap(width: 10, height: 10, scale: 1)
        let mapPints = gameMap.getNeighbourAddresses(to: MapPoint(x: 0, y: 2), radius: 1)
        XCTAssertEqual(mapPints.count, 5)
        /*
         (1,1) | (1,2) | (1,3)
         ------|-------|------
         (0,1) |   P   | (0,3)
         ------|-------|------
           -   |   -   |   -
         */
        XCTAssertTrue(mapPints.contains(MapPoint(x: 1, y: 1)), "1,1")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 1, y: 2)), "1,2")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 1, y: 3)), "1,3")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 0, y: 1)), "0,1")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 0, y: 3)), "0,3")
    }
    
    func test_getNeighbourAddresses_atRightEdge_radius1() {
        let gameMap = GameMap(width: 10, height: 10, scale: 1)
        let mapPints = gameMap.getNeighbourAddresses(to: MapPoint(x: 9, y: 2), radius: 1)
        XCTAssertEqual(mapPints.count, 5)
        /*
           -   |   -   |   -
         ------|-------|------
         (9,1) |   P   | (9,3)
         ------|-------|------
         (8,1) | (8,2) | (8,3)
         */
        XCTAssertTrue(mapPints.contains(MapPoint(x: 9, y: 1)), "9,1")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 9, y: 3)), "9,3")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 8, y: 1)), "8,1")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 8, y: 2)), "8,2")
        XCTAssertTrue(mapPints.contains(MapPoint(x: 8, y: 3)), "8,3")
    }
    
    func test_getNeighbourAddresses_fromMapCentre_radius2() {
        let gameMap = GameMap(width: 10, height: 10, scale: 1)
        let mapPints = gameMap.getNeighbourAddresses(to: MapPoint(x: 2, y: 2), radius: 2)
        XCTAssertEqual(mapPints.count, 16)

    }
}
