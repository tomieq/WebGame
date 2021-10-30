//
//  TileImage.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation

enum TileSide {
    case leftTop
    case rightTop
    case leftBottom
    case rightBottom
}

enum TileType {
    case grass
    case soldLand
    case street(type: StreetType)
    case streetUnderConstruction
    case btsAntenna
    case building(size: Int)
    case buildingUnderConstruction(size: Int)
    case cityCouncil
    case school
    case hospital
    case footballPitch(TileSide)
    case smallFootballPitch
    case warehouse
    case tree(type: Int)
}

extension TileType {
    var image: TileImage {
        switch self {
        case .grass:
            return TileImage(path: "tiles/grass.png", width: 600, height: 400)
        case .footballPitch(let side):
            switch side {
            case .leftTop:
                return TileImage(path: "tiles/pitchLeftTop.png", width: 600, height: 400)
            case .rightTop:
                return TileImage(path: "tiles/pitchRightTop.png", width: 600, height: 400)
            case .leftBottom:
                return TileImage(path: "tiles/pitchLeftBottom.png", width: 600, height: 400)
            case .rightBottom:
                return TileImage(path: "tiles/pitchRightBottom.png", width: 600, height: 400)
            }
        case .smallFootballPitch:
            return TileImage(path: "tiles/pitch.png", width: 600, height: 400)
        case .school:
            return TileImage(path: "tiles/school.png", width: 600, height: 600)
        case .hospital:
            return TileImage(path: "tiles/hospital.png", width: 600, height: 600)
        case .soldLand:
            return TileImage(path: "tiles/sold-land.png", width: 600, height: 400)
        case .btsAntenna:
            return TileImage(path: "tiles/btsAntenna.png", width: 600, height: 800)
        case .building(let size):
            return TileImage(path: "tiles/building-\(size).png", width: 600, height: 900)
        case .buildingUnderConstruction(let size):
            return TileImage(path: "tiles/construction-\(size).png", width: 600, height: 1000)
        case .cityCouncil:
            return TileImage(path: "tiles/city-council.png", width: 600, height: 500)
        case .warehouse:
            return TileImage(path: "tiles/warehouse-1.png", width: 600, height: 600)
        case .tree(let type):
            return TileImage(path: "tiles/tree\(type).png", width: 600, height: 600)
        case .streetUnderConstruction:
            return TileImage(path: "tiles/streetUnderConstruction.png", width: 600, height: 400)
        case .street(let type):
            switch type {

                case .local(let subtype):
                    switch (subtype) {
                    case .localX:
                        return TileImage(path: "tiles/street-X.png", width: 600, height: 400)
                    case .localY:
                        return TileImage(path: "tiles/street-Y.png", width: 600, height: 400)
                    case .localYIntersection1:
                        return TileImage(path: "tiles/street-Y-1.png", width: 600, height: 400)
                    case .localYIntersection2:
                        return TileImage(path: "tiles/street-Y-2.png", width: 600, height: 400)
                    case .localXIntersection1:
                        return TileImage(path: "tiles/street-X-1.png", width: 600, height: 400)
                    case .localXIntersection2:
                        return TileImage(path: "tiles/street-X-2.png", width: 600, height: 400)
                    case .localCross:
                        return TileImage(path: "tiles/street-cross.png", width: 600, height: 400)
                    case .localCurveBottom:
                        return TileImage(path: "tiles/street-curve-bottom.png", width: 600, height: 400)
                    case .localCurveLeft:
                        return TileImage(path: "tiles/street-curve-left.png", width: 600, height: 400)
                    case .localCurveRight:
                        return TileImage(path: "tiles/street-curve-right.png", width: 600, height: 400)
                    case .localCurveTop:
                        return TileImage(path: "tiles/street-curve-top.png", width: 600, height: 400)
                    case .localDeadEndX1:
                        return TileImage(path: "tiles/street-dead-X-1.png", width: 600, height: 400)
                    case .localDeadEndX2:
                        return TileImage(path: "tiles/street-dead-X-2.png", width: 600, height: 400)
                    case .localDeadEndY1:
                        return TileImage(path: "tiles/street-dead-Y-1.png", width: 600, height: 400)
                    case .localDeadEndY2:
                        return TileImage(path: "tiles/street-dead-Y-2.png", width: 600, height: 400)
                    }
                case .main(let subtype):
                    switch (subtype) {
                    case .mainX:
                        return TileImage(path: "tiles/wide-street-X.png", width: 600, height: 400)
                    case .mainY:
                        return TileImage(path: "tiles/wide-street-Y.png", width: 600, height: 400)
                    case .mainCross:
                        return TileImage(path: "tiles/wide-street-cross.png", width: 600, height: 400)
                    case .mainXIntersection1:
                        return TileImage(path: "tiles/wide-street-X-1.png", width: 600, height: 400)
                    case .mainXIntersection2:
                        return TileImage(path: "tiles/wide-street-X-2.png", width: 600, height: 400)
                    case .mainXIntersection3:
                        return TileImage(path: "tiles/wide-street-X-3.png", width: 600, height: 400)
                    case .mainYIntersection1:
                        return TileImage(path: "tiles/wide-street-Y-1.png", width: 600, height: 400)
                    case .mainYIntersection2:
                        return TileImage(path: "tiles/wide-street-Y-2.png", width: 600, height: 400)
                    case .mainYIntersection3:
                        return TileImage(path: "tiles/wide-street-Y-3.png", width: 600, height: 400)
                }
            }
        }
    }
}

extension TileType: Equatable {
    static func == (lhs: TileType, rhs: TileType) -> Bool {
        return lhs.image.path == rhs.image.path
    }
}


struct TileImage {
    let path: String
    let width: Int
    let height: Int
}

enum StreetType {
    case local(LocalStreetType)
    case main(MainStreetType)
}

enum LocalStreetType {
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

enum MainStreetType {
    case mainX
    case mainY
    case mainCross
    case mainXIntersection1
    case mainXIntersection2
    case mainXIntersection3
    case mainYIntersection1
    case mainYIntersection2
    case mainYIntersection3
}
