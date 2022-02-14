//
//  AddonTileType.swift
//  
//
//  Created by Tomasz Kucharski on 14/02/2022.
//

import Foundation

enum CarsOnParkingDirection: String {
    case X
    case Y
}

enum AddonTileType {
    case carsOnParking(direction: CarsOnParkingDirection, size: Int)
    
    var image: TileImage {
        switch self {
        case .carsOnParking(let direction, let size):
            return TileImage(path: "addons/carsOnParking-\(direction.rawValue)-\(size).png", width: 600, height: 400)
        }
    }
}
