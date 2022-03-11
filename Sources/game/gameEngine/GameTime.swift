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

    init(_ month: Int) {
        self.month = month
    }

    func nextMonth() {
        self.month += 1
    }

    var text: String {
        let month = self.month % 12 + 1
        let year = 2000 + (self.month - month + 1) / 12
        return "\(month)/\(year)"
    }
}
