//
//  ParkingBusinessTests.swift
//  
//
//  Created by Tomasz Kucharski on 05/11/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

class ParkingBusinessTests: XCTestCase {
    
    func test_amountOfCarsNearbyResidentialBuilding() {
        let sut = self.makeSUT()
        sut.mapManager.loadMapFrom(content: "b")
        XCTAssertEqual(sut.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 4)
    }
    
    func test_amountOfCarsTwoTilesAwayFromResidentialBuilding() {
        let sut = self.makeSUT()
        sut.mapManager.loadMapFrom(content: "b,R")
        XCTAssertEqual(sut.calculateCarsForParking(address: MapPoint(x: 0, y: 2)), 4 + 10)
    }
    
    func test_amountOfCarsNearbyHospital() {
        let sut = self.makeSUT()
        sut.mapManager.loadMapFrom(content: "-,H")
        XCTAssertEqual(sut.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 12)
    }
    
    func test_amountOfCarsNearSchool() {
        let sut = self.makeSUT()
        sut.mapManager.loadMapFrom(content: "-,Q")
        XCTAssertEqual(sut.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 5)
    }
    
    func test_amountOfCars_twoParkingsOneBuilding() {
        let sut = self.makeSUT()
        sut.mapManager.loadMapFrom(content: "R,c\ns,s,s,s")
        XCTAssertEqual(sut.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 10 / 2)
    }
    
    func test_amountOfparkingsInTheArea() {
        let sut = self.makeSUT()
        sut.mapManager.loadMapFrom(content: "s,s,s\nc,-,c")
        XCTAssertEqual(sut.getParkingsAroundAddress(MapPoint(x: 1, y: 1)).count, 2)
    }
    
    private func makeSUT() -> ParkingBusiness {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 40, height: 40, scale: 1)
        let mapManager = GameMapManager(map)
        let parkingBusiness = ParkingBusiness(mapManager: mapManager, dataStore: dataStore)
        return parkingBusiness
    }
}
