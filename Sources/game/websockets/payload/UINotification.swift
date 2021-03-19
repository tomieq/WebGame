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

struct UINotification: Codable {
    let text: String
    let level: UINotificationLevel
    let duration: Int
}
