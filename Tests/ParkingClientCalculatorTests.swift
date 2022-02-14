//
//  ParkingClientCalculatorTests.swift
//  
//
//  Created by Tomasz Kucharski on 14/02/2022.
//

import Foundation
import XCTest
@testable import WebGameLib

class ParkingClientCalculatorTests: XCTestCase {

    func test_amountOfCarsNearbyResidentialBuilding() {
        let calculator = self.makeCalculator()
        calculator.mapManager.loadMapFrom(content: "b")
        XCTAssertEqual(calculator.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 4)
    }
    
    func test_amountOfCarsTwoTilesAwayFromResidentialBuilding() {
        let calculator = self.makeCalculator()
        calculator.mapManager.loadMapFrom(content: "b,R")
        XCTAssertEqual(calculator.calculateCarsForParking(address: MapPoint(x: 0, y: 2)), 4 + 10)
    }
    
    func test_amountOfCarsNearbyHospital() {
        let calculator = self.makeCalculator()
        calculator.mapManager.loadMapFrom(content: "-,H")
        XCTAssertEqual(calculator.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 12)
    }

    func test_amountOfCarsNearbyTwoHospitals() {
        let calculator = self.makeCalculator()
        calculator.mapManager.loadMapFrom(content: "H,H")
        XCTAssertEqual(calculator.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 24)
    }
    
    func test_amountOfCarsNearSchool() {
        let calculator = self.makeCalculator()
        calculator.mapManager.loadMapFrom(content: "-,Q")
        XCTAssertEqual(calculator.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 5)
    }
    
    func test_amountOfparkingsInTheArea() {
        let calculator = self.makeCalculator()
        calculator.mapManager.loadMapFrom(content: "s,s,s\nc,-,c")
        XCTAssertEqual(calculator.getParkingsAroundAddress(MapPoint(x: 1, y: 1)).count, 2)
    }
    
    func test_amountOfCars_twoParkingsOneBuilding() {
        let calculator = self.makeCalculator()
        let layout = """
                    R,c,c
                    s,s,s,s
                    """
        calculator.mapManager.loadMapFrom(content: layout)
        XCTAssertEqual(calculator.calculateCarsForParking(address: MapPoint(x: 2, y: 0)), 10 / 2)
    }
    
    func test_amountOfCars_threeParkingsOneBuilding() {
        let calculator = self.makeCalculator()
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,-,B,-,c
                    -,-,-,c,
                    """
        calculator.mapManager.loadMapFrom(content: layout)
        XCTAssertEqual(calculator.calculateCarsForParking(address: MapPoint(x: 3, y: 2)), 6 / 3)
    }
    
    func test_amountOfCars_threeParkingsTwoBuildings() {
        let calculator = self.makeCalculator()
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,R,B,-,c
                    -,-,-,c,
                    """
        calculator.mapManager.loadMapFrom(content: layout)
        XCTAssertEqual(calculator.calculateCarsForParking(address: MapPoint(x: 3, y: 2)), 6 / 3 + 10 / 2)
    }
    
    func test_amountOfCarsTwoParkings_lowerTrust() {
        let calculator = self.makeCalculator()
        let dataStore = calculator.dataStore
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,B,c
                    """
        calculator.mapManager.loadMapFrom(content: layout)
        let address1 = MapPoint(x: 1, y: 1)
        let address2 = MapPoint(x: 3, y: 1)
        
        let uuid = dataStore.create(Parking(land: Land(address: address1)))
        dataStore.create(Parking(land: Land(address: address2), trustLevel: 0.5))
        
        XCTAssertEqual(calculator.calculateCarsForParking(address: address1), 4)
        XCTAssertEqual(calculator.calculateCarsForParking(address: address2), 2)
        
        dataStore.update(ParkingMutation(uuid: uuid, attributes: [.trustLevel(0.5)]))
        XCTAssertEqual(calculator.calculateCarsForParking(address: address1), 3)
    }
    
    func test_amountOfCarsThreeParkings_lowerTrust() {
        let calculator = self.makeCalculator()
        let dataStore = calculator.dataStore
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,B,c,c
                    """
        calculator.mapManager.loadMapFrom(content: layout)
        let address1 = MapPoint(x: 1, y: 1)
        let address2 = MapPoint(x: 3, y: 1)
        let address3 = MapPoint(x: 4, y: 1)
        
        dataStore.create(Parking(land: Land(address: address1)))
        dataStore.create(Parking(land: Land(address: address2), trustLevel: 0.5))
        dataStore.create(Parking(land: Land(address: address3), trustLevel: 0.5))
        
        XCTAssertEqual(calculator.calculateCarsForParking(address: address1), 3)
        XCTAssertEqual(calculator.calculateCarsForParking(address: address2), 1.5)
        XCTAssertEqual(calculator.calculateCarsForParking(address: address3), 1.5)
    }
    
    private func makeCalculator() -> ParkingClientCalculator {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 40, height: 40, scale: 1)
        let mapManager = GameMapManager(map)
        return ParkingClientCalculator(mapManager: mapManager, dataStore: dataStore)
    }
}
