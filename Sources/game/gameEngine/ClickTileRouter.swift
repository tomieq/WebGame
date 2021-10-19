//
//  ClickTileRouter.swift
//  
//
//  Created by Tomasz Kucharski on 19/10/2021.
//

import Foundation


class ClickTileRouter {
    
    enum Action {
        case roadInfo
        case landInfo
        case buyLandOffer
        case buyResidentialBuildingOffer
        case landManager
        case residentialBuildingManager
        case noAction
    }
    
    let map: GameMap
    let dataStore: DataStoreProvider
    
    init(map: GameMap, dataStore: DataStoreProvider) {
        self.map = map
        self.dataStore = dataStore
    }
    
    func action(address: MapPoint, playerUUID: String?) -> Action {
        let tile = self.map.getTile(address: address)
        guard let tile = tile else {
            return .buyLandOffer
        }
        if tile.isStreet() {
            return .roadInfo
        }
        if tile.isBuilding(), let building: ResidentialBuilding = self.dataStore.find(address: address) {
            if building.ownerUUID == playerUUID {
                return .residentialBuildingManager
            } else {
                return .buyResidentialBuildingOffer
            }
        }
        if let land: Land = self.dataStore.find(address: address) {
            if land.ownerUUID == playerUUID {
                return .landManager
            } else {
                return .landInfo
            }
        }
        return .noAction
    }
}
