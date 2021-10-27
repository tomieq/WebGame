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
    case residentialBuildingInfo
    case buyLand
    case buyResidentialBuilding
    case roadManager
    case landManager
    case residentialBuildingManager
    case footballPitchInfo
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
            switch tile.type {
            case .footballPitch(_):
                return .footballPitchInfo
            default:
                return .noAction
            }
            
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
                } else if self.agent.isForSale(address: address) {
                    return .buyResidentialBuilding
                } else {
                    return .residentialBuildingInfo
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
                .openWindow(OpenWindow(title: "Road info", width: 400, height: 250, initUrl: RestEndpoint.openRoadInfo.append(point), address: point))
            ]
        case .roadManager:
            return  [
                .openWindow(OpenWindow(title: "Road manager", width: 0.7, height: 250, initUrl: RestEndpoint.openRoadManager.base.append(point), address: point))
            ]
        case .landInfo:
            return [
                .openWindow(OpenWindow(title: "Property info", width: 400, height: 200, initUrl: RestEndpoint.openPropertyInfo.base.append(point), address: point))
            ]
        case .buyLand:
            return [
                .openWindow(OpenWindow(title: "Sale offer", width: 300, height: 270, initUrl: RestEndpoint.openSaleOffer.append(point), address: point))
            ]
        case .buyResidentialBuilding:
            return [
                .openWindow(OpenWindow(title: "Sale offer", width: 300, height: 270, initUrl: RestEndpoint.openSaleOffer.append(point), address: point))
            ]
        case .landManager:
            return [
                .openWindow(OpenWindow(title: "Loading", width: 0.7, height: 100, initUrl: RestEndpoint.openLandManager.append(point), address: point))
            ]
        case .residentialBuildingInfo:
            return [
                .openWindow(OpenWindow(title: "Property info", width: 400, height: 200, initUrl: RestEndpoint.openPropertyInfo.base.append(point), address: point))
            ]
        case .residentialBuildingManager:
            return [
                .openWindow(OpenWindow(title: "Loading", width: 0.7, height: 100, initUrl: RestEndpoint.openBuildingManager.append(point), address: point))
            ]
        case .footballPitchInfo:
            return  [
                .openWindow(OpenWindow(title: "Football Pitch", width: 400, height: 250, initUrl: RestEndpoint.footballPitchInfo.append(point), address: point))
            ]
        case .noAction:
            return []
        }
    }
}
