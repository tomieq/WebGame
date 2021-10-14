//
//  PriceList.swift
//  
//
//  Created by Tomasz Kucharski on 25/03/2021.
//

import Foundation

class PriceList {
    public static let baseLandValue: Double = 90000
    
    public static let residentialBuildingOwnerIncomeOnFlatSellPrice: Double = 75000
    
    public static let instantSellValue: Double = 0.85
    public static let realEstateSellPropertyCommisionFee = 0.01
    // property value loss
    public static let propertyValueDistanceFromRoadLoss: Double = 0.6
    // property value gain
    public static let propertyValueDistanceFromResidentialBuildingGain = 0.4
    // montly costs
    public static let montlyResidentialBuildingCost = 1300.0
    public static let montlyResidentialBuildingCostPerStorey = 1100.0
    public static let monthlyResidentialBuildingOwnerIncomePerFlat: Double = 300.0
    public static let monthlyBillsForRentedApartment: Double = 452.0
    public static let monthlyBillsForUnrentedApartment: Double = 180.0
    public static let monthlyApartmentRentalFee: Double = 2330
    public static let monthlyApartmentBuildingOwnerFee: Double = 930
}
