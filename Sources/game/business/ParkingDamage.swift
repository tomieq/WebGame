//
//  ParkingDamage.swift
//  
//
//  Created by Tomasz Kucharski on 06/11/2021.
//

import Foundation

enum ParkingDamageType: CaseIterable {
    case brokenMirror
    case tirePuncture
    case brokenWindow
    case stolenWiper
    case brokenHeadLight
    case brokenBackLight
    case stolenCupWheels
    case stolenWheels
    case dentedCarRoof
    case grafittiOnCar
    case stolenCar
    case carArsonry
    
    var name: String {
        switch self {
            
        case .brokenMirror:
            return "broken car's mirror"
        case .tirePuncture:
            return "punctured tire"
        case .brokenWindow:
            return "broken window"
        case .stolenWiper:
            return "stolen wiper"
        case .brokenHeadLight:
            return "broken head light"
        case .brokenBackLight:
            return "broken back light"
        case .stolenCupWheels:
            return "stolen cup wheels"
        case .stolenWheels:
            return "stolen car wheels"
        case .dentedCarRoof:
            return "dented car's roof"
        case .grafittiOnCar:
            return "grafitti on car's hood"
        case .stolenCar:
            return "car stolen"
        case .carArsonry:
            return "car arsoned"
        }
    }
    
    var trustLoose: Double {
        switch self {
        case .brokenMirror:
            return 0.04
        case .tirePuncture:
            return 0.08
        case .brokenWindow:
            return 0.09
        case .stolenWiper:
            return 0.02
        case .brokenHeadLight:
            return 0.07
        case .brokenBackLight:
            return 0.04
        case .stolenCupWheels:
            return 0.03
        case .stolenWheels:
            return 0.12
        case .dentedCarRoof:
            return 0.21
        case .grafittiOnCar:
            return 0.32
        case .stolenCar:
            return 0.67
        case .carArsonry:
            return 0.93
        }
    }
    
    var fixPrice: Double {
        switch self {
            
        case .brokenMirror:
            return Double.random(in: 80...145)
        case .tirePuncture:
            return Double.random(in: 320...545)
        case .brokenWindow:
            return Double.random(in: 320...545)
        case .stolenWiper:
            return Double.random(in: 12...46)
        case .brokenHeadLight:
            return Double.random(in: 212...646)
        case .brokenBackLight:
            return Double.random(in: 112...346)
        case .stolenCupWheels:
            return Double.random(in: 60...140)
        case .stolenWheels:
            return Double.random(in: 612...1846)
        case .dentedCarRoof:
            return Double.random(in: 2340...6450)
        case .grafittiOnCar:
            return Double.random(in: 1000...1999)
        case .stolenCar:
            return Double.random(in: 23000...80299)
        case .carArsonry:
            return Double.random(in: 23000...80299)
        }
    }
}

enum ParkingDamageStatus: Equatable {
    case coveredByInsurance
    case awaitingPayment
    case partiallyCoveredByInsurance(Double)
    case paid
    
    var name: String {
        switch self {
        case .coveredByInsurance:
            return "Damage fully covered by insurance"
        case .awaitingPayment:
            return "Awaiting payment"
        case .partiallyCoveredByInsurance(let value):
            return "Insurance policy covered \(value.money)"
        case .paid:
            return "Fylly paid"
        }
    }
    
    var isClosed: Bool {
        switch self {
        case .paid, .coveredByInsurance:
            return true
        default:
            return false
        }
    }
}

class ParkingDamage {
    let type: ParkingDamageType
    let fixPrice: Double
    let accidentMonth: Int
    let criminalUUID: String?
    let car: String
    var status: ParkingDamageStatus
    
    init(type: ParkingDamageType, accidentMonth: Int, criminalUUID: String? = nil) {
        self.type = type
        self.fixPrice = type.fixPrice.rounded(toPlaces: 0)
        self.accidentMonth = accidentMonth
        self.criminalUUID = criminalUUID
        self.car = CarGenerator.shared.ramdomCar()
        self.status = .awaitingPayment
    }
}
