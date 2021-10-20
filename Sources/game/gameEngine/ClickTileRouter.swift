//
//  ClickTileRouter.swift
//  
//
//  Created by Tomasz Kucharski on 19/10/2021.
//

import Foundation

enum ClickTileAction {
    case roadInfo
    case landInfo
    case buyLandOffer
    case buyResidentialBuildingOffer
    case landManager
    case residentialBuildingManager
    case noAction
}

extension ClickTileAction {
    func commandPayload(_ point: MapPoint) -> OpenWindow? {
        switch self {
            
        case .roadInfo:
            return OpenWindow(title: "Property info", width: 400, height: 200, initUrl: "/openPropertyInfo.js?x=\(point.x)&y=\(point.y)", address: point)
        case .landInfo:
            return OpenWindow(title: "Property info", width: 400, height: 200, initUrl: "/openPropertyInfo.js?x=\(point.x)&y=\(point.y)", address: point)
        case .buyLandOffer:
            return OpenWindow(title: "Sale offer", width: 300, height: 250, initUrl: "/openSaleOffer.js?type=land&x=\(point.x)&y=\(point.y)", address: point)
        case .buyResidentialBuildingOffer:
            return OpenWindow(title: "Sale offer", width: 300, height: 250, initUrl: "/openSaleOffer.js?type=building&x=\(point.x)&y=\(point.y)", address: point)
        case .landManager:
            return OpenWindow(title: "Loading", width: 0.7, height: 100, initUrl: "/openPropertyManager.js?type=land&x=\(point.x)&y=\(point.y)", address: nil)
        case .residentialBuildingManager:
            return OpenWindow(title: "Loading", width: 0.7, height: 100, initUrl: "/openPropertyManager.js?type=building&x=\(point.x)&y=\(point.y)", address: nil)
        case .noAction:
            return nil
        }
    }
}

class ClickTileRouter {
    
    let map: GameMap
    let dataStore: DataStoreProvider
    
    init(map: GameMap, dataStore: DataStoreProvider) {
        self.map = map
        self.dataStore = dataStore
    }
    
    func action(address: MapPoint, playerUUID: String?) -> ClickTileAction {
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
