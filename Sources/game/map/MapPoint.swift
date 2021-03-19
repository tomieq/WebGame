//
//  MapPoint.swift
//  
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

struct MapPoint: Codable {
    let x: Int
    let y: Int
}

enum MapDirection: CaseIterable {
    case right
    case left
    case up
    case down
}

extension MapPoint: Equatable {
    
}

extension MapPoint {
    
    func move(_ direction: MapDirection) -> MapPoint {
        switch direction {
        case .right:
            return MapPoint(x: self.x + 1, y: self.y)
        case .left:
            return MapPoint(x: self.x - 1, y: self.y)
        case .up:
            return MapPoint(x: self.x, y: self.y - 1)
        case .down:
            return MapPoint(x: self.x, y: self.y + 1)
        }
    }
}

extension MapPoint: CustomStringConvertible {
    public var description: String {
        return "(\(self.x),\(self.y))"
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

extension MapPoint {
    var asQueryParams: String {
        return "x=\(self.x)&y=\(self.y)"
    }
}
