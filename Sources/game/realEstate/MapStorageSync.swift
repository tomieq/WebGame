//
//  MapStorageSync.swift
//  
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation


class MapStorageSync {
    let mapManager: GameMapManager
    let dataStore: DataStoreProvider
    
    init(mapManager: GameMapManager, dataStore: DataStoreProvider) {
        self.mapManager = mapManager
        self.dataStore = dataStore
    }
    
    func syncMapWithDataStore() {
        
        var buildingToAdd: [ResidentialBuilding] = []
        for tile in self.mapManager.map.tiles {
            switch tile.type {
            case .building(let size):
                let building = ResidentialBuilding(land: Land(address: tile.address, ownerUUID: SystemPlayer.government.uuid), storeyAmount: size)
                buildingToAdd.append(building)
            case .parking(_):
                let parking = Parking(land: Land(address: tile.address, ownerUUID: SystemPlayer.investor.uuid))
                let parkingUUID = self.dataStore.create(parking)
                let register = PropertyRegister(uuid: parkingUUID, address: tile.address, playerUUID: SystemPlayer.investor.uuid, type: .parking)
                self.dataStore.create(register)
            default:
                break
            }
        }
        
        let lands: [Land] = self.dataStore.getAll()
        for land in lands  {
            self.mapManager.addPrivateLand(address: land.address)
        }
        let roads: [Road] = self.dataStore.getAll()
        for road in roads {
            if road.isUnderConstruction {
                let tile = GameMapTile(address: road.address, type: .streetUnderConstruction)
                self.mapManager.map.replaceTile(tile: tile)
            } else {
                self.mapManager.addStreet(address: road.address)
            }
        }
        
        let buildings: [ResidentialBuilding] = self.dataStore.getAll()
        for building in buildings {
            if building.isUnderConstruction {
                let tile = GameMapTile(address: building.address, type: .buildingUnderConstruction(size: building.storeyAmount))
                self.mapManager.map.replaceTile(tile: tile)
            } else {
                let tile = GameMapTile(address: building.address, type: .building(size: building.storeyAmount))
                self.mapManager.map.replaceTile(tile: tile)
            }
        }
        for building in buildingToAdd {
            if (!buildings.contains{ $0.address == building.address }) {
                self.dataStore.create(building)
            }
        }
    }
}
