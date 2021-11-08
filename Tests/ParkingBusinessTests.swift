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
        let business = self.makeParkingBusiness()
        business.mapManager.loadMapFrom(content: "b")
        XCTAssertEqual(business.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 4)
    }
    
    func test_amountOfCarsTwoTilesAwayFromResidentialBuilding() {
        let business = self.makeParkingBusiness()
        business.mapManager.loadMapFrom(content: "b,R")
        XCTAssertEqual(business.calculateCarsForParking(address: MapPoint(x: 0, y: 2)), 4 + 10)
    }
    
    func test_amountOfCarsNearbyHospital() {
        let business = self.makeParkingBusiness()
        business.mapManager.loadMapFrom(content: "-,H")
        XCTAssertEqual(business.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 12)
    }
    
    func test_amountOfCarsNearSchool() {
        let business = self.makeParkingBusiness()
        business.mapManager.loadMapFrom(content: "-,Q")
        XCTAssertEqual(business.calculateCarsForParking(address: MapPoint(x: 1, y: 1)), 5)
    }
    
    func test_amountOfparkingsInTheArea() {
        let business = self.makeParkingBusiness()
        business.mapManager.loadMapFrom(content: "s,s,s\nc,-,c")
        XCTAssertEqual(business.getParkingsAroundAddress(MapPoint(x: 1, y: 1)).count, 2)
    }
    
    func test_amountOfCars_twoParkingsOneBuilding() {
        let business = self.makeParkingBusiness()
        let layout = """
                    R,c,c
                    s,s,s,s
                    """
        business.mapManager.loadMapFrom(content: layout)
        XCTAssertEqual(business.calculateCarsForParking(address: MapPoint(x: 2, y: 0)), 10 / 2)
    }
    
    func test_amountOfCars_threeParkingsOneBuilding() {
        let business = self.makeParkingBusiness()
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,-,B,-,c
                    -,-,-,c,
                    """
        business.mapManager.loadMapFrom(content: layout)
        XCTAssertEqual(business.calculateCarsForParking(address: MapPoint(x: 3, y: 2)), 6 / 3)
    }
    
    func test_amountOfCars_threeParkingsTwoBuildings() {
        let business = self.makeParkingBusiness()
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,R,B,-,c
                    -,-,-,c,
                    """
        business.mapManager.loadMapFrom(content: layout)
        XCTAssertEqual(business.calculateCarsForParking(address: MapPoint(x: 3, y: 2)), 6 / 3 + 10 / 2)
    }
    
    func test_amountOfCarsTwoParkings_lowerTrust() {
        let business = self.makeParkingBusiness()
        let dataStore = business.dataStore
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,B,c
                    """
        business.mapManager.loadMapFrom(content: layout)
        let address1 = MapPoint(x: 1, y: 1)
        let address2 = MapPoint(x: 3, y: 1)
        
        let uuid = dataStore.create(Parking(land: Land(address: address1)))
        dataStore.create(Parking(land: Land(address: address2), trustLevel: 0.5))
        
        XCTAssertEqual(business.calculateCarsForParking(address: address1), 4)
        XCTAssertEqual(business.calculateCarsForParking(address: address2), 2)
        
        dataStore.update(ParkingMutation(uuid: uuid, attributes: [.trustLevel(0.5)]))
        XCTAssertEqual(business.calculateCarsForParking(address: address1), 3)
    }
    
    func test_amountOfCarsThreeParkings_lowerTrust() {
        let business = self.makeParkingBusiness()
        let dataStore = business.dataStore
        let layout = """
                    s,s,s,s,s,s,s,s,s
                    -,c,B,c,c
                    """
        business.mapManager.loadMapFrom(content: layout)
        let address1 = MapPoint(x: 1, y: 1)
        let address2 = MapPoint(x: 3, y: 1)
        let address3 = MapPoint(x: 4, y: 1)
        
        dataStore.create(Parking(land: Land(address: address1)))
        dataStore.create(Parking(land: Land(address: address2), trustLevel: 0.5))
        dataStore.create(Parking(land: Land(address: address3), trustLevel: 0.5))
        
        XCTAssertEqual(business.calculateCarsForParking(address: address1), 3)
        XCTAssertEqual(business.calculateCarsForParking(address: address2), 1.5)
        XCTAssertEqual(business.calculateCarsForParking(address: address3), 1.5)
    }
    
    func test_addDamageOwnerWithoutInsurance() {
        let business = self.makeParkingBusiness()
        let dataStore = business.dataStore
        let address = MapPoint(x: 1, y: 1)
        dataStore.create(Parking(land: Land(address: address)))
        business.addDamage(ParkingDamage(type: .stolenWheels, accidentMonth: 0), address: address)
        let damages = business.getDamages(address: address)
        XCTAssertEqual(damages.count, 1)
        XCTAssertEqual(damages.first?.status, .awaitingPayment)
    }
    
    func test_addDamageLowInsurance() {
        let business = self.makeParkingBusiness()
        let dataStore = business.dataStore
        let address = MapPoint(x: 1, y: 1)
        let insurance = ParkingInsurance.basic

        let uuid = dataStore.create(Parking(land: Land(address: address)))
        dataStore.update(ParkingMutation(uuid: uuid, attributes: [.insurance(insurance)]))
        business.addDamage(ParkingDamage(type: .stolenWheels, accidentMonth: 0), address: address)
        let damages = business.getDamages(address: address)
        XCTAssertEqual(damages.count, 1)
        XCTAssertEqual(damages.first?.status, .partiallyCoveredByInsurance(insurance.damageCoverLimit))
    }
    
    func test_addDamageFullInsurance() {
        let business = self.makeParkingBusiness()
        let dataStore = business.dataStore
        let address = MapPoint(x: 1, y: 1)
        let insurance = ParkingInsurance.full

        let uuid = dataStore.create(Parking(land: Land(address: address)))
        dataStore.update(ParkingMutation(uuid: uuid, attributes: [.insurance(insurance)]))
        business.addDamage(ParkingDamage(type: .stolenWheels, accidentMonth: 0), address: address)
        let damages = business.getDamages(address: address)
        XCTAssertEqual(damages.count, 1)
        XCTAssertEqual(damages.first?.status, .coveredByInsurance)
    }
    
    private func makeParkingBusiness() -> ParkingBusiness {
        let dataStore = DataStoreMemoryProvider()
        let map = GameMap(width: 40, height: 40, scale: 1)
        let mapManager = GameMapManager(map)
        let parkingBusiness = ParkingBusiness(mapManager: mapManager, dataStore: dataStore)
        return parkingBusiness
    }
}
