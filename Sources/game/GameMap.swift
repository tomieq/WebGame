//
//  GameMap.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation

class GameMap {
    typealias MapMatrix = [Int:[Int:String]]
    var tiles: [GameMapTile] = []
    
    init() {
        //self.tiles.append(GameMapTile(x: 0, y: 0, image: .grass))
        //self.tiles.append(GameMapTile(x: 0, y: 1, image: .street(type: .x)))
        self.loadStreets("maps/roadMap1")
    }
    
    private func loadStreets(_ path: String) {
        if let content = try? String(contentsOfFile: Resource.absolutePath(forAppResource: path)) {
            let lines = content.components(separatedBy: "\n")
            var matrix: MapMatrix = [:] // matrix[x][y] = "s"
            lines.enumerated().forEach { (y, line) in
                let elements = line.components(separatedBy: ",")
                elements.enumerated().forEach { (x, chr) in
                    if matrix[x] == nil { matrix[x] = [:] }
                    matrix[x]?[y] = chr
                }
            }
            matrix.forEach { dataX in
                dataX.value.forEach { dataY in
                    if dataY.value == "s" {
                        self.tiles.append(GameMapTile(x: dataX.key, y: dataY.key, image: .street(type: self.evaluateStreetType(x: dataX.key, y: dataY.key, mapMatrix: matrix))))
                    }
                }
            }
        }
    }
    
    private func evaluateStreetType(x: Int, y: Int, mapMatrix: MapMatrix) -> StreetType {
        let topTile = mapMatrix[x]?[y-1] == "s"
        let bottomTile = mapMatrix[x]?[y+1] == "s"
        let leftTile = mapMatrix[x-1]?[y] == "s"
        let righTile = mapMatrix[x+1]?[y] == "s"
        
        switch (topTile, bottomTile, leftTile, righTile) {
            case (true, true, true, true):
                return .localCross
            case (true, true, true, false):
                return .localYIntersection1
            case (true, true, false, true):
                return .localYIntersection2
            case (false, true, true, true):
                return .localXIntersection2
            case (true, false, true, true):
                return .localXIntersection1
            case (true, false, false, true):
                return .localCurveTop
            case (false, true, true, false):
                return .localCurveBottom
            case (true, false, true, false):
                return .localCurveLeft
            case (false, true, false, true):
                return .localCurveRight
            case (true, true, false, false):
                return .localY
            case (false, false, true, true):
                return .localX
            case (false, false, false, true):
                return .localDeadEndX1
            case (false, false, true, false):
                return .localDeadEndX2
            case (false, true, false, false):
                return .localDeadEndY1
            case (true, false, false, false):
                return .localDeadEndY2
            default:
                return .localCross
        }
        return .localCross
    }
}

struct GameMapTile {
    let x: Int
    let y: Int
    let image: TileImage
}
