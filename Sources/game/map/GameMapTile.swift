//
//  GameMapTile.swift
//  
//
//  Created by Tomasz Kucharski on 13/02/2022.
//

import Foundation

struct GameMapTile {
    let address: MapPoint
    let type: TileType
}

enum GameMapPropertyType {
    case land
    case road
    case parking
    case residentialBuilding
}

extension GameMapTile {
    func isStreet() -> Bool {
        if case .street(_) = self.type {
            return true
        }
        return false
    }
    
    func isParking() -> Bool {
        if case .parking(_) = self.type {
            return true
        }
        return false
    }

    func isStreetUnderConstruction() -> Bool {
        if case .streetUnderConstruction = self.type {
            return true
        }
        return false
    }

    func isBuilding() -> Bool {
        if case .building = self.type {
            return true
        }
        return false
    }
    
    func isBuildingUnderConstruction() -> Bool {
        if case .buildingUnderConstruction = self.type {
            return true
        }
        return false
    }
    
    func isOffice() -> Bool {
        if case .office = self.type {
            return true
        }
        return false
    }
    
    func isAntenna() -> Bool {
        if case .btsAntenna = self.type {
            return true
        }
        return false
    }
    
    var propertyType: GameMapPropertyType? {
        switch self.type {
            
        case .soldLand:
            return .land
        case .street(_), .streetUnderConstruction:
            return .road
        case .parking(_), .parkingUnderConstruction:
            return .parking
        case .building(_, _), .buildingUnderConstruction(_):
            return .residentialBuilding
        default:
            return nil
        }
        
    }
}
