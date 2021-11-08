//
//  ParkingInsurance.swift
//  
//
//  Created by Tomasz Kucharski on 08/11/2021.
//

import Foundation

enum ParkingInsurance: String, CaseIterable {
    case none
    case basic
    case extended
    case full
    case sleepWell
    
    var monthlyFee: Double {
        switch self {
        case .none:
            return 0
        case .basic:
            return 280
        case .extended:
            return 620
        case .full:
            return 1380
        case .sleepWell:
            return 2500
        }
    }
    
    var damageCoverLimit: Double {
        switch self {
            
        case .none:
            return 0
        case .basic:
            return 1000
        case .extended:
            return 10000
        case .full:
            return 100000
        case .sleepWell:
            return 1000000
        }
    }
    
    var name: String {
        switch self {
        case .none:
            return "No insurance"
        case .basic:
            return "Basic insurance"
        case .extended:
            return "Extended insurance"
        case .full:
            return "Full insurance"
        case .sleepWell:
            return "Sleep Well insurance"
        }
    }
}
