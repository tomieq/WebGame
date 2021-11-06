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
    
    func test_amountOfparkingsInTheArea() {
        let sut = self.makeSUT()
        sut.mapManager.loadMapFrom(content: "s,s,s\nc,-,c")
        XCTAssertEqual(sut.getParkingsAroundAddress(MapPoint(x: 1, y: 1)).count, 2)
    }
    
    func test_amountOfCars_twoParkingsOneBuilding() {
        let sut = self.makeSUT()
        let layout = """
                    R,c,c
                    s,s,s,s
                    """
        sut.mapManager.loadMapFrom(content: layout)
        XCTAssertEqual(sut.calculateCarsForParking(address: MapPoint(x: 2, y: 0)), 10 / 2)
    }
    
    func test_amountOfCars_threeParkingsOneBuilding() {
        let sut = self.makeSUT()
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,-,B,-,c
                    -,-,-,c,
                    """
        sut.mapManager.loadMapFrom(content: layout)
        XCTAssertEqual(sut.calculateCarsForParking(address: MapPoint(x: 3, y: 2)), 6 / 3)
    }
    
    func test_amountOfCars_threeParkingsTwoBuildings() {
        let sut = self.makeSUT()
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,R,B,-,c
                    -,-,-,c,
                    """
        sut.mapManager.loadMapFrom(content: layout)
        XCTAssertEqual(sut.calculateCarsForParking(address: MapPoint(x: 3, y: 2)), 6 / 3 + 10 / 2)
    }
    
    func test_amountOfCarsTwoParkings_lowerTrust() {
        let sut = self.makeSUT()
        let dataStore = sut.dataStore
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,B,c
                    """
        sut.mapManager.loadMapFrom(content: layout)
        let address1 = MapPoint(x: 1, y: 1)
        let address2 = MapPoint(x: 3, y: 1)
        
        let uuid = dataStore.create(Parking(land: Land(address: address1)))
        dataStore.create(Parking(land: Land(address: address2), trustLevel: 0.5))
        
        XCTAssertEqual(sut.calculateCarsForParking(address: address1), 4)
        XCTAssertEqual(sut.calculateCarsForParking(address: address2), 2)
        
        dataStore.update(ParkingMutation(uuid: uuid, attributes: [.trustLevel(0.5)]))
        XCTAssertEqual(sut.calculateCarsForParking(address: address1), 3)
    }
    
    func test_amountOfCarsThreeParkings_lowerTrust() {
        let sut = self.makeSUT()
        let dataStore = sut.dataStore
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,B,c,c
                    """
        sut.mapManager.loadMapFrom(content: layout)
        let address1 = MapPoint(x: 1, y: 1)
        let address2 = MapPoint(x: 3, y: 1)
        let address3 = MapPoint(x: 4, y: 1)
        
        dataStore.create(Parking(land: Land(address: address1)))
        dataStore.create(Parking(land: Land(address: address2), trustLevel: 0.5))
        dataStore.create(Parking(land: Land(address: address3), trustLevel: 0.5))
        
        XCTAssertEqual(sut.calculateCarsForParking(address: address1), 3)
        XCTAssertEqual(sut.calculateCarsForParking(address: address2), 1.5)
        XCTAssertEqual(sut.calculateCarsForParking(address: address3), 1.5)
        
        
    }
    
    private func makeSUT() -> ParkingBusiness {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 40, height: 40, scale: 1)
        let mapManager = GameMapManager(map)
        let parkingBusiness = ParkingBusiness(mapManager: mapManager, dataStore: dataStore)
        return parkingBusiness
    }
}
