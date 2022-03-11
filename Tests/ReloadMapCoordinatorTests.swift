//
//  ReloadMapCoordinatorTests.swift
//
//
//  Created by Tomasz Kucharski on 25/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

class ReloadMapCoordinatorTests: XCTestCase {
    func test_instantReload() {
        var counter = 0

        let coordinator = ReloadMapCoordinator()
        coordinator.setFlushAction {
            counter += 1
        }

        XCTAssertEqual(counter, 0)
        coordinator.reloadMap()
        XCTAssertEqual(counter, 1)
    }

    func test_holdReloadOnce() {
        var counter = 0
        let coordinator = ReloadMapCoordinator()
        coordinator.setFlushAction {
            counter += 1
        }

        XCTAssertEqual(counter, 0)
        coordinator.hold()
        coordinator.reloadMap()
        XCTAssertEqual(counter, 0)
        coordinator.flush()
        XCTAssertEqual(counter, 1)
    }

    func test_holdReloadMultipleTimes() {
        var counter = 0
        let coordinator = ReloadMapCoordinator()
        coordinator.setFlushAction {
            counter += 1
        }

        XCTAssertEqual(counter, 0)
        coordinator.hold()
        coordinator.reloadMap()
        coordinator.reloadMap()
        coordinator.reloadMap()
        coordinator.reloadMap()
        coordinator.reloadMap()
        XCTAssertEqual(counter, 0)
        coordinator.flush()
        XCTAssertEqual(counter, 1)
    }

    func test_flushMultipleTimes() {
        var counter = 0
        let coordinator = ReloadMapCoordinator()
        coordinator.setFlushAction {
            counter += 1
        }

        XCTAssertEqual(counter, 0)
        coordinator.hold()
        coordinator.reloadMap()
        coordinator.reloadMap()
        coordinator.reloadMap()
        XCTAssertEqual(counter, 0)
        coordinator.flush()
        XCTAssertEqual(counter, 1)
        coordinator.flush()
        coordinator.flush()
        coordinator.flush()
        XCTAssertEqual(counter, 1)
    }

    func test_checkNotBlocked() {
        var counter = 0
        let coordinator = ReloadMapCoordinator()
        coordinator.setFlushAction {
            counter += 1
        }

        XCTAssertEqual(counter, 0)
        coordinator.hold()
        coordinator.reloadMap()
        coordinator.reloadMap()
        coordinator.reloadMap()
        XCTAssertEqual(counter, 0)
        coordinator.flush()
        XCTAssertEqual(counter, 1)
        coordinator.reloadMap()
        XCTAssertEqual(counter, 2)
        coordinator.reloadMap()
        XCTAssertEqual(counter, 3)
    }
}
