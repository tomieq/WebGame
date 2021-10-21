//
//  RealEstateMarket.swift
//  
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation

enum RealEstateMarketError: Error {
    case propertyDoesNotExist
}

class RealEstateMarket {
    private let gameMap: GameMap
    private let dataStore: DataStoreProvider
    
    init(gameMap: GameMap, dataStore: DataStoreProvider) {
        self.gameMap = gameMap
        self.dataStore = dataStore
    }
    
    func createOffer(address: MapPoint, netValue: Double) throws {
        guard self.gameMap.isAddressOnMap(address) else {
            throw RealEstateMarketError.propertyDoesNotExist
        }
        guard let propertyType = self.gameMap.getTile(address: address)?.propertyType else {
            throw RealEstateMarketError.propertyDoesNotExist
        }
        let property: Property?
        switch propertyType {
            
        case .land:
            let land: Land? = self.dataStore.find(address: address)
            property = land
        case .road:
            let road: Road? = self.dataStore.find(address: address)
            property = road
        case .residentialBuilding:
            let building: ResidentialBuilding? = self.dataStore.find(address: address)
            property = building
        }
        guard let property = property else {
            throw RealEstateMarketError.propertyDoesNotExist
        }
    }
}
