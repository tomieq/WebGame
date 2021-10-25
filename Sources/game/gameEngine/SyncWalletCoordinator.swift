//
//  SyncWalletCoordinator.swift
//  
//
//  Created by Tomasz Kucharski on 25/10/2021.
//

import Foundation

class SyncWalletCoordinator {
    private var blocked = false
    private var playerUUIDs: [String] = []
    private var action: ((_: String) -> Void)?
    
    func setSyncWalletChange(action: @escaping (_: String) -> Void) {
        self.action = action
    }
    
    func hold() {
        self.blocked = true
    }
    
    func flush() {
        self.blocked = false
        if self.playerUUIDs.count > 0 {
            for playerUUID in self.playerUUIDs {
                self.action?(playerUUID)
            }
            self.playerUUIDs = []
        }
    }
    
    func syncWalletChange(playerUUID: String) {
        if self.blocked {
            if !self.playerUUIDs.contains(playerUUID) {
                self.playerUUIDs.append(playerUUID)
            }
            return
        }
        self.action?(playerUUID)
    }
    
}
