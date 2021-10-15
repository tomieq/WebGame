//
//  MapPointTests.swift
//  
//
//  Created by Tomasz Kucharski on 14/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class MapPointTests: XCTestCase {
    
    func test_MapPointEquality_sameAddress() {
        let point1 = MapPoint(x: 2, y: 8)
        let point2 = MapPoint(x: 2, y: 8)
        XCTAssertEqual(point1, point2)
    }

    func test_MapPointEquality_swithedAddress() {
        let point1 = MapPoint(x: 8, y: 2)
        let point2 = MapPoint(x: 2, y: 8)
        XCTAssertNotEqual(point1, point2)
    }
    
    func test_MapPointMoveUp() {
        /*
          --------
         ⎹ •  x → ⎸
         ⎹ y      ⎸
         ⎹ ↓      ⎸up = y - 1
          --------
         */
        let point = MapPoint(x: 3, y: 1)
        let newAddress = point.move(.up)
        let expectedAddress = MapPoint(x: 3, y: 0)
        XCTAssertEqual(newAddress, expectedAddress)
    }
    
    func test_MapPointMoveDown() {
        /*
          --------
         ⎹ •  x → ⎸
         ⎹ y      ⎸
         ⎹ ↓      ⎸down = y + 1
          --------
         */
        let point = MapPoint(x: 3, y: 1)
        let newAddress = point.move(.down)
        let expectedAddress = MapPoint(x: 3, y: 2)
        XCTAssertEqual(newAddress, expectedAddress)
    }
    
    func test_MapPointMoveRight() {
        /*
          --------
         ⎹ •  x → ⎸
         ⎹ y      ⎸
         ⎹ ↓      ⎸right = x + 1
          --------
         */
        let point = MapPoint(x: 3, y: 1)
        let newAddress = point.move(.right)
        let expectedAddress = MapPoint(x: 4, y: 1)
        XCTAssertEqual(newAddress, expectedAddress)
    }
    
    func test_MapPointMoveLeft() {
        /*
          --------
         ⎹ •  x → ⎸
         ⎹ y      ⎸
         ⎹ ↓      ⎸left = x - 1
          --------
         */
        let point = MapPoint(x: 3, y: 1)
        let newAddress = point.move(.left)
        let expectedAddress = MapPoint(x: 2, y: 1)
        XCTAssertEqual(newAddress, expectedAddress)
    }
    
    func test_MapPointQueryParams() {
        let point = MapPoint(x: 3, y: 1)
        XCTAssertEqual(point.asQueryParams, "x=3&y=1")
    }
    
    func test_MapPointHashable() {
        let point1 = MapPoint(x: 3, y: 1)
        let point2 = MapPoint(x: 3, y: 1)
        
        var dictionary: [MapPoint: Int] = [:]
        dictionary[point1] = 4
        XCTAssertEqual(dictionary[point1], 4)
        dictionary[point2] = 5
        XCTAssertEqual(dictionary.count, 1)
        XCTAssertEqual(dictionary[point2], 5)
        XCTAssertEqual(dictionary[point1], 5)
    }
}
