//
//  InvestmentPrice.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class InvestmentPrice {

    public static func buildingRoad() -> Double {
        return 410000
    }
    
    public static func buildingApartment(storey: Int) -> Double {
        return (2300000 + Double(storey) * 840000).rounded(toPlaces: 0)
    }
}

class InvestmentDuration {
    public static func buildingRoad() -> Int {
        return 3
    }
    public static func buildingApartment(storey: Int) -> Int {
        return 9 + storey
    }
}
