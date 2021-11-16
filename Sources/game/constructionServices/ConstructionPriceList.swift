//
//  ConstructionPriceList.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation

class ConstructionPriceList {
    
    var buildRoadPrice: Double = 410000
    var buildParkingPrice: Double = 130000
    var buildResidentialBuildingPrice: Double = 2300000
    var buildResidentialBuildingPricePerStorey: Double = 840000
    var residentialBuildingElevatorPricePerStorey: Double = 23000
    
    func buildResidentialBuildingPrice(storey: Int, elevator: Bool) -> Double {
        var price = self.buildResidentialBuildingPrice
        price += storey.double * self.buildResidentialBuildingPricePerStorey
        if elevator {
            price += storey.double * self.residentialBuildingElevatorPricePerStorey
        }
        return price.rounded(toPlaces: 0)
    }
}

class ConstructionDuration {
    var road: Int = 3
    var parking: Int = 2
    var residentialBuilding = 9
    var residentialBuildingPerStorey = 1
    
    func residentialBuilding(storey: Int) -> Int {
        return self.residentialBuilding + storey * self.residentialBuildingPerStorey
    }
}
