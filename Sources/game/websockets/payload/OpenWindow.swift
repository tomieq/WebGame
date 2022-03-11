//
//  OpenWindow.swift
//
//
//  Created by Tomasz Kucharski on 18/03/2021.
//

import Foundation

struct OpenWindow: Codable {
    let title: String
    let width: Double
    let height: Double
    let initUrl: String
    let address: MapPoint?
}
