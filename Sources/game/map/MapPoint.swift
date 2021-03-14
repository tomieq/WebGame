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

extension MapPoint {
    func moveRight() -> MapPoint {
        return MapPoint(x: self.x + 1, y: self.y)
    }
    
    func moveLeft() -> MapPoint {
        return MapPoint(x: self.x - 1, y: self.y)
    }
    
    func moveUp() -> MapPoint {
        return MapPoint(x: self.x, y: self.y - 1)
    }
    
    func moveDown() -> MapPoint {
        return MapPoint(x: self.x, y: self.y + 1)
    }
}

extension MapPoint: CustomStringConvertible {
    public var description: String {
        return "[\(self.x),\(self.y)]"
    }
}

extension MapPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
  
    static public func ==(lhs: MapPoint, rhs: MapPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}
