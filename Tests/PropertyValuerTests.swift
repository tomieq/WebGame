//
//  PropertyValuerTests.swift
//  
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class PropertyValuerTests: XCTestCase {
    
    func test_estimateLandValueAtRoad() {
        let valuer = self.makeValuer()
        valuer.valueFactors.baseLandValue = 100
        let mapContent = "s,s"
        valuer.mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 100)
    }
    
    func test_estimateLandValueOneTileFromRoad() {
        let valuer = self.makeValuer()
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueDistanceFromRoadLoss = 0.5
        let mapContent = "s,s"
        valuer.mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 2))
        XCTAssertEqual(price, 50)
    }
    
    func test_estimateLandValueTwoTilesFromRoad() {
        let valuer = self.makeValuer()
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueDistanceFromRoadLoss = 0.5
        let mapContent = "s,s"
        valuer.mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 3))
        XCTAssertEqual(price, 25)
    }

    func test_estimateLandValueNextToBuilding() {
        let valuer = self.makeValuer()
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueDistanceFromResidentialBuildingGain = 0.5
        let mapContent = "s,s,B"
        valuer.mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 1, y: 1))
        XCTAssertEqual(price, 150)
    }

    func test_estimateLandValueNextToTwoBuildings() {
        let valuer = self.makeValuer()
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueDistanceFromResidentialBuildingGain = 0.5
        let mapContent = "s,s,B\nB"
        valuer.mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 1, y: 1))
        XCTAssertEqual(price, 200)
    }
    
    func test_estimateLandValueTwoTilesFromBuilding() {
        let valuer = self.makeValuer()
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueDistanceFromResidentialBuildingGain = 0.5
        let mapContent = "s,s,B"
        valuer.mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 125)
    }
    
    func test_estimateLandValueOneTileFromAntenna() {
        let valuer = self.makeValuer()
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,A"
        valuer.mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 1, y: 1))
        XCTAssertEqual(price, 20)
    }
    
    func test_estimateLandValueTwoTilesFromAntenna() {
        let valuer = self.makeValuer()
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,A"
        valuer.mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 40)
    }
    
    func test_estimateLandValueThreeTilesFromAntenna() {
        let valuer = self.makeValuer()
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,s,A"
        valuer.mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 60)
    }
    
    func test_estimateLandValueFourTilesFromAntenna() {
        let valuer = self.makeValuer()
        valuer.valueFactors.baseLandValue = 100
        valuer.valueFactors.propertyValueAntennaSurroundingLoss = 0.2
        let mapContent = "s,s,s,s,A"
        valuer.mapManager.loadMapFrom(content: mapContent)
        
        let price = valuer.estimateValue(MapPoint(x: 0, y: 1))
        XCTAssertEqual(price, 100)
    }
    
    private func makeValuer() -> PropertyValuer {
        
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 200, height: 200, scale: 0.2)
        let mapManager = GameMapManager(map)
        let time = GameTime()
        let taxRates = TaxRates()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates, time: time)
        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        let parkingBusiness = ParkingBusiness(mapManager: mapManager, dataStore: dataStore)
        let balanceCalculator = PropertyBalanceCalculator(mapManager: mapManager, parkingBusiness: parkingBusiness, taxRates: taxRates)
        let valuer = PropertyValuer(balanceCalculator: balanceCalculator, constructionServices: constructionServices)
        return valuer
    }
}
