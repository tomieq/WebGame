//
//  TileImage.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation

enum TileImage {
    case grass
    case street(type: StreetType)
}

extension TileImage {
    var info: TileImageInfo {
        switch self {
        case .grass:
            return TileImageInfo(path: "tiles/grass.png", width: 600, height: 400)
        case .street(let type):
            switch type {
            case .localX:
                return TileImageInfo(path: "tiles/street-X.png", width: 600, height: 400)
            case .localY:
                return TileImageInfo(path: "tiles/street-Y.png", width: 600, height: 400)
            case .localYIntersection1:
                return TileImageInfo(path: "tiles/street-Y-1.png", width: 600, height: 400)
            case .localYIntersection2:
                return TileImageInfo(path: "tiles/street-Y-2.png", width: 600, height: 400)
            case .localXIntersection1:
                return TileImageInfo(path: "tiles/street-X-1.png", width: 600, height: 400)
            case .localXIntersection2:
                return TileImageInfo(path: "tiles/street-X-2.png", width: 600, height: 400)
            case .localCross:
                return TileImageInfo(path: "tiles/street-cross.png", width: 600, height: 400)
            case .localCurveBottom:
                return TileImageInfo(path: "tiles/street-curve-bottom.png", width: 600, height: 400)
            case .localCurveLeft:
                return TileImageInfo(path: "tiles/street-curve-left.png", width: 600, height: 400)
            case .localCurveRight:
                return TileImageInfo(path: "tiles/street-curve-right.png", width: 600, height: 400)
            case .localCurveTop:
                return TileImageInfo(path: "tiles/street-curve-top.png", width: 600, height: 400)
            case .localDeadEndX1:
                return TileImageInfo(path: "tiles/street-dead-X-1.png", width: 600, height: 400)
            case .localDeadEndX2:
                return TileImageInfo(path: "tiles/street-dead-X-2.png", width: 600, height: 400)
            case .localDeadEndY1:
                return TileImageInfo(path: "tiles/street-dead-Y-1.png", width: 600, height: 400)
            case .localDeadEndY2:
                return TileImageInfo(path: "tiles/street-dead-Y-2.png", width: 600, height: 400)
            }
        }
    }
}


struct TileImageInfo {
    let path: String
    let width: Int
    let height: Int
}

enum StreetType {
    case localX
    case localY
    case localYIntersection1
    case localYIntersection2
    case localXIntersection1
    case localXIntersection2
    case localCross
    case localCurveBottom
    case localCurveLeft
    case localCurveRight
    case localCurveTop
    case localDeadEndX1
    case localDeadEndX2
    case localDeadEndY1
    case localDeadEndY2
}
