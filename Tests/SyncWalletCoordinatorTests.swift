//
//  SyncWalletCoordinatorTests.swift
//  
//
//  Created by Tomasz Kucharski on 25/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

class SyncWalletCoordinatorTests: XCTestCase {

    func test_normalSingleSync() {
        let coordinator = SyncWalletCoordinator()
        var users: [String] = []
        
        coordinator.setSyncWalletChange { playerUUID in
            users.append(playerUUID)
        }
        
        coordinator.syncWalletChange(playerUUID: "john")
        XCTAssertEqual(users.count, 1)
        XCTAssertTrue(users.contains("john"))
    }
    
    func test_normalMultipleSync() {
        let coordinator = SyncWalletCoordinator()
        var users: [String] = []
        
        coordinator.setSyncWalletChange { playerUUID in
            users.append(playerUUID)
        }
        
        coordinator.syncWalletChange(playerUUID: "john")
        coordinator.syncWalletChange(playerUUID: "tom")
        XCTAssertEqual(users.count, 2)
        XCTAssertTrue(users.contains("john"))
        XCTAssertTrue(users.contains("tom"))
    }

    func test_holdSync() {
        let coordinator = SyncWalletCoordinator()
        var users: [String] = []
        
        coordinator.setSyncWalletChange { playerUUID in
            users.append(playerUUID)
        }
        coordinator.hold()
        coordinator.syncWalletChange(playerUUID: "john")
        coordinator.syncWalletChange(playerUUID: "tom")
        XCTAssertEqual(users.count, 0)
        coordinator.flush()
        XCTAssertEqual(users.count, 2)
        XCTAssertTrue(users.contains("john"))
        XCTAssertTrue(users.contains("tom"))
    }

    func test_flushMultipleTimes() {
        let coordinator = SyncWalletCoordinator()
        var users: [String] = []
        
        coordinator.setSyncWalletChange { playerUUID in
            users.append(playerUUID)
        }
        coordinator.hold()
        coordinator.syncWalletChange(playerUUID: "john")
        coordinator.syncWalletChange(playerUUID: "tom")
        XCTAssertEqual(users.count, 0)
        coordinator.flush()
        coordinator.flush()
        coordinator.flush()
        XCTAssertEqual(users.count, 2)
        XCTAssertTrue(users.contains("john"))
        XCTAssertTrue(users.contains("tom"))
    }
    
    func test_worksNormalAfterFlush() {
        let coordinator = SyncWalletCoordinator()
        var users: [String] = []
        
        coordinator.setSyncWalletChange { playerUUID in
            users.append(playerUUID)
        }
        coordinator.hold()
        coordinator.syncWalletChange(playerUUID: "john")
        coordinator.syncWalletChange(playerUUID: "tom")
        XCTAssertEqual(users.count, 0)
        coordinator.flush()
        XCTAssertEqual(users.count, 2)
        XCTAssertTrue(users.contains("john"))
        XCTAssertTrue(users.contains("tom"))
        coordinator.syncWalletChange(playerUUID: "jane")
        XCTAssertEqual(users.count, 3)
        XCTAssertTrue(users.contains("jane"))
    }
}
