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
    case buyLand
    case buyResidentialBuilding
    case roadManager
    case landManager
    case residentialBuildingManager
    case noAction
}

class ClickTileRouter {
    
    let map: GameMap
    let dataStore: DataStoreProvider
    let agent: RealEstateAgent
    
    init(agent: RealEstateAgent) {
        self.map = agent.mapManager.map
        self.dataStore = agent.dataStore
        self.agent = agent
    }
    
    func action(address: MapPoint, playerUUID: String?) -> ClickTileAction {
        let tile = self.map.getTile(address: address)
        guard let tile = tile else {
            return .buyLand
        }
        guard let propertyType = tile.propertyType else {
            return .noAction
        }
        switch propertyType {
        case .land:
            if let land: Land = self.dataStore.find(address: address) {
                if land.ownerUUID == playerUUID {
                    return .landManager
                } else if self.agent.isForSale(address: address) {
                    return .buyLand
                } else {
                    return .landInfo
                }
            }
        case .road:
            if let road: Road = self.dataStore.find(address: address), road.ownerUUID == playerUUID {
                return .roadManager
            }
            return .roadInfo
        case .residentialBuilding:
            if let building: ResidentialBuilding = self.dataStore.find(address: address) {
                if building.ownerUUID == playerUUID {
                    return .residentialBuildingManager
                } else {
                    return .buyResidentialBuilding
                }
            }
        }
        return .noAction
    }
}

extension ClickTileAction {
    func commands( point: MapPoint) -> [WebsocketOutCommand] {
        switch self {
            
        case .roadInfo:
            return  [
                .openWindow(OpenWindow(title: "Road info", width: 400, height: 250, initUrl: "/openRoadInfo.js?\(point.asQueryParams)", address: point))
            ]
        case .roadManager:
            return  [
                .openWindow(OpenWindow(title: "Road manager", width: 0.7, height: 250, initUrl: "/openRoadManager.js?\(point.asQueryParams)", address: point))
            ]
        case .landInfo:
            return [
                .openWindow(OpenWindow(title: "Property info", width: 400, height: 200, initUrl: "/openPropertyInfo.js?\(point.asQueryParams)", address: point))
            ]
        case .buyLand:
            return [
                .openWindow(OpenWindow(title: "Sale offer", width: 300, height: 270, initUrl: "/openSaleOffer.js?\(point.asQueryParams)", address: point))
            ]
        case .buyResidentialBuilding:
            return [
                .openWindow(OpenWindow(title: "Sale offer", width: 300, height: 270, initUrl: "/openSaleOffer.js?\(point.asQueryParams)", address: point))
            ]
        case .landManager:
            return [
                .openWindow(OpenWindow(title: "Loading", width: 0.7, height: 100, initUrl: "/openLandManager.js?\(point.asQueryParams)", address: nil))
            ]
        case .residentialBuildingManager:
            return [
                .openWindow(OpenWindow(title: "Loading", width: 0.7, height: 100, initUrl: "/openPropertyManager.js?type=building&\(point.asQueryParams)", address: nil))
            ]
        case .noAction:
            return []
        }
    }
}
