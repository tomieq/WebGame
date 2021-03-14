//
//  MapPoint.swift
//  
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

struct MapPoint {
    let x: Int
    let y: Int
}

extension MapPoint: CustomStringConvertible {
    public var description: String {
        return "[\(self.x),\(self.y)]"
    }
}
