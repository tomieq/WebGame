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
            case .x:
                return TileImageInfo(path: "tiles/street-X.png", width: 600, height: 400)
            case .y:
                return TileImageInfo(path: "tiles/street-Y.png", width: 600, height: 400)
            case .yIntersection1:
                return TileImageInfo(path: "tiles/street-Y-1.png", width: 600, height: 400)
            case .yIntersection2:
                return TileImageInfo(path: "tiles/street-Y-2.png", width: 600, height: 400)
            case .xIntersection1:
                return TileImageInfo(path: "tiles/street-X-1.png", width: 600, height: 400)
            case .xIntersection2:
                return TileImageInfo(path: "tiles/street-X-2.png", width: 600, height: 400)
            case .cross:
                return TileImageInfo(path: "tiles/street-cross.png", width: 600, height: 400)
            case .curveBottom:
                return TileImageInfo(path: "tiles/street-curve-bottom.png", width: 600, height: 400)
            case .curveLeft:
                return TileImageInfo(path: "tiles/street-curve-left.png", width: 600, height: 400)
            case .curveRight:
                return TileImageInfo(path: "tiles/street-curve-right.png", width: 600, height: 400)
            case .curveTop:
                return TileImageInfo(path: "tiles/street-curve-top.png", width: 600, height: 400)
            case .deadEndX1:
                return TileImageInfo(path: "tiles/street-dead-X-1.png", width: 600, height: 400)
            case .deadEndX2:
                return TileImageInfo(path: "tiles/street-dead-X-2.png", width: 600, height: 400)
            case .deadEndY1:
                return TileImageInfo(path: "tiles/street-dead-Y-1.png", width: 600, height: 400)
            case .deadEndY2:
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
    case x
    case y
    case yIntersection1
    case yIntersection2
    case xIntersection1
    case xIntersection2
    case cross
    case curveBottom
    case curveLeft
    case curveRight
    case curveTop
    case deadEndX1
    case deadEndX2
    case deadEndY1
    case deadEndY2
}
