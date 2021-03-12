//
//  Logger.swift
//  
//
//  Created by Tomasz Kucharski on 28/12/2020.
//

import Foundation

class Logger {
    
    enum Level: String {
        case error
        case warning
        case info
        case debug
    }
    
    static func error(_ label: String, _ text: String) {
        Logger.log(.error, label, text)
    }
    static func warning(_ label: String, _ text: String) {
        Logger.log(.warning, label, text)
    }
    static func info(_ label: String, _ text: String) {
        Logger.log(.info, label, text)
    }
    static func debug(_ label: String, _ text: String) {
        Logger.log(.debug, label, text)
    }
    
    private static func log(_ level: Level, _ label: String, _ text: String) {
        print("\(level.rawValue):\t\(label.isEmpty ? "" : "[\(label)] ")\(text)")
    }
}
