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
    case parkingInfo
    case parkingManager
    case buyParking
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
        case .parking:
            if let parking: Parking = self.dataStore.find(address: address) {
                if parking.ownerUUID == playerUUID {
                    return .parkingManager
                } else if self.agent.isForSale(address: address) {
                    return .buyParking
                } else {
                    return .parkingInfo
                }
            }
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
    func commands(point: MapPoint) -> [WebsocketOutCommand] {
        switch self {
        case .roadInfo:
            return [.runScript(RestEndpoint.openRoadInfo.append(point))]
        case .roadManager:
            return [.runScript(RestEndpoint.openRoadManager.base.append(point))]
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
            return [.runScript(RestEndpoint.openLandManager.append(point))]
        case .residentialBuildingInfo:
            return [
                .openWindow(OpenWindow(title: "Property info", width: 400, height: 200, initUrl: RestEndpoint.openPropertyInfo.base.append(point), address: point))
            ]
        case .residentialBuildingManager:
            return [.runScript(RestEndpoint.openBuildingManager.append(point))]
        case .footballPitchInfo:
            return [.runScript(RestEndpoint.openFootballPitch.append(point))]
        case .parkingInfo:
            return [
                .openWindow(OpenWindow(title: "Property info", width: 400, height: 200, initUrl: RestEndpoint.openPropertyInfo.base.append(point), address: point))
            ]
        case .parkingManager:
            return [.runScript(RestEndpoint.openParkingManager.base.append(point))]
        case .buyParking:
            return [
                .openWindow(OpenWindow(title: "Sale offer", width: 300, height: 270, initUrl: RestEndpoint.openSaleOffer.append(point), address: point))
            ]
        case .noAction:
            return []
        }
    }
}
