//
//  PriceList.swift
//  
//
//  Created by Tomasz Kucharski on 25/03/2021.
//

import Foundation

class PriceList {
    public var baseLandValue: Double = 90000
    
    public var residentialBuildingOwnerIncomeOnFlatSellPrice: Double = 75000
    
    public var realEstateSellLandPropertyCommisionFee: Double = 200
    public var realEstateSellResidentialBuildingCommisionFee: Double = 1000
    public var realEstateSellPropertyCommisionRate: Double = 0.01
    // property value loss
    public var propertyValueDistanceFromRoadLoss: Double = 0.6
    public var propertyValueAntennaSurroundingLoss: Double = 0.22
    // property value gain
    public var propertyValueDistanceFromResidentialBuildingGain: Double = 0.2
    // montly costs
    public var montlyResidentialBuildingCost: Double = 1300.0
    public var montlyResidentialBuildingCostPerStorey: Double = 1100.0
    public var monthlyResidentialBuildingOwnerIncomePerFlat: Double = 300.0
    public var monthlyBillsForRentedApartment: Double = 452.0
    public var monthlyBillsForUnrentedApartment: Double = 180.0
    public var monthlyApartmentRentalFee: Double = 2300
    public var monthlyApartmentBuildingOwnerFee: Double = 930
}
