//
//  ConstructionServicesTests.swift
//  
//
//  Created by Tomasz Kucharski on 18/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib


final class ConstructionServicesTests: XCTestCase {
    
    func test_RoadOfferDuration() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.constructionDuration.road = 10
        
        let offer = constructionServices.roadOffer(landName: "Sample Name")
        XCTAssertEqual(offer.duration, 10)
    }
    
    func test_RoadOfferPrice() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.priceList.buildRoadPrice = 10000
        
        let offer = constructionServices.roadOffer(landName: "Sample Name")
        XCTAssertEqual(offer.invoice.netValue, 10000)
    }

    func test_RoadOfferTaxRate() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        centralBank.taxRates.investmentTax = 0.5
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.priceList.buildRoadPrice = 10000
        
        let offer = constructionServices.roadOffer(landName: "Sample Name")
        XCTAssertEqual(offer.invoice.netValue, 10000)
        XCTAssertEqual(offer.invoice.tax, 5000)
    }
    
    func test_residentialBuildingOfferDuration() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.constructionDuration.residentialBuilding = 100
        constructionServices.constructionDuration.residentialBuildingPerStorey = 10
        
        let offer = constructionServices.residentialBuildingOffer(landName: "Test", storeyAmount: 4)
        XCTAssertEqual(offer.duration, 140)
    }
    
    func test_ResidentialBuildingOfferPrice() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.priceList.buildResidentialBuildingPrice = 10000
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 20
        
        let offer = constructionServices.residentialBuildingOffer(landName: "test", storeyAmount: 3)
        XCTAssertEqual(offer.invoice.netValue, 10060)
    }
    
    func test_ResidentialBuildingOfferTaxRate() {
        let map = GameMap(width: 2, height: 2, scale: 0.2)
        let mapManager = GameMapManager(map)
        
        let time = GameTime()
        
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates)
        centralBank.taxRates.investmentTax = 0.5
        
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        constructionServices.priceList.buildResidentialBuildingPrice = 10000
        constructionServices.priceList.buildResidentialBuildingPricePerStorey = 1000
        
        let offer = constructionServices.residentialBuildingOffer(landName: "test", storeyAmount: 10)
        XCTAssertEqual(offer.invoice.netValue, 20000)
        XCTAssertEqual(offer.invoice.tax, 10000)
    }
}
