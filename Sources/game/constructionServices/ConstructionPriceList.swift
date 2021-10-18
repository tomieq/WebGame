//
//  ConstructionPriceList.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class ConstructionPriceList {
    
    var buildRoadPrice: Double = 410000
    var buildResidentialBuildingPrice: Double = 2300000
    var buildResidentialBuildingPricePerStorey: Double = 840000
    
    func buildResidentialBuildingPrice(storey: Int) -> Double {
        return (self.buildResidentialBuildingPrice + storey.double * self.buildResidentialBuildingPricePerStorey).rounded(toPlaces: 0)
    }
}

class ConstructionDuration {
    public static func buildingRoad() -> Int {
        return 3
    }
    public static func buildingApartment(storey: Int) -> Int {
        return 9 + storey
    }
}
