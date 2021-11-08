//
//  ParkingAdvertising.swift
//  
//
//  Created by Tomasz Kucharski on 08/11/2021.
//

import Foundation

enum ParkingAdvertising: String, CaseIterable {
    case none
    case leaflets
    case localNewspaperAd
    case radioAd
    case tvSpot
    
    var monthlyFee: Double {
        switch self {
        case .none:
            return 0
        case .leaflets:
            return 210
        case .localNewspaperAd:
            return 490
        case .radioAd:
            return 920
        case .tvSpot:
            return 2100
        }
    }
    var name: String {
        switch self {
        case .none:
            return "No advertising"
        case .leaflets:
            return "Leaflets to local area"
        case .localNewspaperAd:
            return "Advert in local newspaper"
        case .radioAd:
            return "Advert in local radio station"
        case .tvSpot:
            return "TV spot in local station"
        }
    }
    var monthlyTrustGain: Double {
        switch self {
        case .none:
            return 0
        case .leaflets:
            return 0.05
        case .localNewspaperAd:
            return 0.15
        case .radioAd:
            return 0.21
        case .tvSpot:
            return 0.34
        }
    }
}
