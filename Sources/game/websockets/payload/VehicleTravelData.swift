//
//  VehicleTravelData.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

struct VehicleTravelData: Codable {
    let id: String
    let speed: UInt
    let vehicleType: String
    let travelPoints: [MapPoint]
}
