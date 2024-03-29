//
//  Double+extension.swift
//
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation

extension Double {
    var string: String {
        return "\(self)"
    }

    var money: String {
        return "$ \(self.moneyFormat)"
    }

    var moneyFormat: String {
        return String(format: "%.0f", self).split(every: 3, backwards: true).joined(separator: " ").replacingOccurrences(of: "- ", with: "-")
    }

    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    var int: Int {
        return Int(self)
    }
}
