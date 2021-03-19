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
        return "$ \(String(format: "%.0f", self).split(every: 3, backwards: true).joined(separator: " "))"
    }
}
