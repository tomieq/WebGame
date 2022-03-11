//
//  VehicleTravel.swift
//
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

struct VehicleTravelStarted: Codable, Equatable {
    let id: String
    let speed: UInt
    let vehicleType: String
    let travelPoints: [MapPoint]
}

struct VehicleTravelFinished: Codable {
    let id: String
    let address: MapPoint
}
