//
//  GameTime.swift
//  
//
//  Created by Tomasz Kucharski on 18/10/2021.
//

import Foundation

class GameTime {
    var month: Int
    
    init() {
        self.month = 0
    }
    
    func nextMonth() {
        self.month += 1
    }
}
