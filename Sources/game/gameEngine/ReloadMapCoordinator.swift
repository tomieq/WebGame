//
//  ReloadMapCoordinator.swift
//  
//
//  Created by Tomasz Kucharski on 25/10/2021.
//

import Foundation

class ReloadMapCoordinator {
    private var blocked = false
    private var waitingReload = false
    private var action: (() -> Void)?
    
    func setFlushAction(action: @escaping () -> Void) {
        self.action = action
    }
    
    func hold() {
        self.blocked = true
    }
    
    func flush() {
        if self.waitingReload {
            self.action?()
            self.waitingReload = false
        }
        self.blocked = false
    }
    
    func reloadMap() {
        if self.blocked {
            self.waitingReload = true
            return
        }
        self.action?()
    }
}
