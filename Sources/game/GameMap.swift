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
                return .cross
            case (true, true, true, false):
                return .yIntersection1
            case (true, true, false, true):
                return .yIntersection2
            case (false, true, true, true):
                return .xIntersection2
            case (true, false, true, true):
                return .xIntersection1
            case (true, false, false, true):
                return .curveTop
            case (false, true, true, false):
                return .curveBottom
            case (true, false, true, false):
                return .curveLeft
            case (false, true, false, true):
                return .curveRight
            case (true, true, false, false):
                return .y
            case (false, false, true, true):
                return .x
            case (false, false, false, true):
                return .deadEndX1
            case (false, false, true, false):
                return .deadEndX2
            case (false, true, false, false):
                return .deadEndY1
            case (true, false, false, false):
                return .deadEndY2
            default:
                return .cross
        }
        return .cross
    }
}

struct GameMapTile {
    let x: Int
    let y: Int
    let image: TileImage
}
