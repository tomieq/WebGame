//
//  RealEstateMarketTests.swift
//  
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib


final class RealEstateMarketTests: XCTestCase {
    
    func test_createOfferOutsideMap() {
        
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 10, height: 10, scale: 0.5)
        let market = RealEstateMarket(gameMap: map, dataStore: dataStore)
        
        XCTAssertThrowsError(try market.createOffer(address: MapPoint(x: 30, y: 30), netValue: 3000)){ error in
            XCTAssertEqual(error as? RealEstateMarketError, .propertyDoesNotExist)
        }
    }
    
    func test_createOfferOnNonExistingProperty() {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 10, height: 10, scale: 0.5)
        let market = RealEstateMarket(gameMap: map, dataStore: dataStore)
        
        XCTAssertThrowsError(try market.createOffer(address: MapPoint(x: 5, y: 5), netValue: 3000)){ error in
            XCTAssertEqual(error as? RealEstateMarketError, .propertyDoesNotExist)
        }
    }
}
