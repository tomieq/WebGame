//
//  ParkingSecurity.swift
//  
//
//  Created by Tomasz Kucharski on 08/11/2021.
//

import Foundation

enum ParkingSecurity: String, CaseIterable {
    case none
    case cctv
    case nightGuard
    case securityGuard
    
    var monthlyFee: Double {
        switch self {
        case .none:
            return 0
        case .cctv:
            return 520
        case .nightGuard:
            return 2180
        case .securityGuard:
            return 4300
        }
    }
    var name: String {
        switch self {
        case .none:
            return "No security"
        case .cctv:
            return "CCTV"
        case .nightGuard:
            return "Night security guard"
        case .securityGuard:
            return "Security guard 24/7"
        }
    }

    var effectiveneness: Int {
        switch self {
        case .none:
            return 0
        case .cctv:
            return 61
        case .nightGuard:
            return 83
        case .securityGuard:
            return 99
        }
    }
}
