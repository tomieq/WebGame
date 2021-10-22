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
    var road: Int = 3
    var residentialBuilding = 9
    var residentialBuildingPerStorey = 1
    
    func residentialBuilding(storey: Int) -> Int {
        return self.residentialBuilding + storey * self.residentialBuildingPerStorey
    }
}
