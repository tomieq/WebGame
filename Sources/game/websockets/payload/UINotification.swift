//
//  UINotification.swift
//  
//
//  Created by Tomasz Kucharski on 19/03/2021.
//

import Foundation

enum UINotificationLevel: String, Codable {
    case error
    case warning
    case success
    case info
}

enum UINotificationIcon: String, Codable {
    case none = ""
    case police
    case court
    case property
    case betting
    case money
    case moneyWarning
    case redFlag
    case bribe
    case carDamage
    case insurance
    case security
    case marketing
}

struct UINotification: Codable {
    let text: String
    let level: UINotificationLevel
    let duration: Int
    let icon: String
    
    init(text: String, level: UINotificationLevel, duration: Int, icon: UINotificationIcon = .none) {
        self.text = text
        self.level = level
        self.duration = duration
        self.icon = icon.rawValue
    }
}
