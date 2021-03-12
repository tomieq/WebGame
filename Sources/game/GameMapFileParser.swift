//
//  GameMapFileParser.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation

class GameMapFileParser {
    typealias MapMatrix = [Int:[Int:GameMapFileChar]]
    
    func loadStreets(_ path: String) -> [GameMapTile] {
        var mapTiles: [GameMapTile] = []
        if let content = try? String(contentsOfFile: Resource.absolutePath(forAppResource: path)) {
            let lines = content.components(separatedBy: "\n")
            var matrix: MapMatrix = [:] // matrix[x][y] = "s"
            lines.enumerated().forEach { (y, line) in
                let elements = line.components(separatedBy: ",")
                elements.enumerated().forEach { (x, chr) in
                    if matrix[x] == nil { matrix[x] = [:] }
                    matrix[x]?[y] = GameMapFileChar(rawValue: chr)
                }
            }
            matrix.forEach { dataX in
                dataX.value.forEach { dataY in
                    if dataY.value == .localStreet {
                        mapTiles.append(GameMapTile(x: dataX.key, y: dataY.key, image: .street(type: self.evaluateStreetType(x: dataX.key, y: dataY.key, mapMatrix: matrix))))
                    }
                }
            }
        }
        return mapTiles
    }
    
    private func evaluateStreetType(x: Int, y: Int, mapMatrix: MapMatrix) -> StreetType {
        let topTile = mapMatrix[x]?[y-1]
        let bottomTile = mapMatrix[x]?[y+1]
        let leftTile = mapMatrix[x-1]?[y]
        let righTile = mapMatrix[x+1]?[y]
        
        switch (topTile, bottomTile, leftTile, righTile) {
            case (.localStreet, .localStreet, .localStreet, .localStreet):
                return .localCross
            case (.localStreet, .localStreet, .localStreet, _):
                return .localYIntersection1
            case (.localStreet, .localStreet, _, .localStreet):
                return .localYIntersection2
            case (_, .localStreet, .localStreet, .localStreet):
                return .localXIntersection2
            case (.localStreet, _, .localStreet, .localStreet):
                return .localXIntersection1
            case (.localStreet, _, _, .localStreet):
                return .localCurveTop
            case (_, .localStreet, .localStreet, _):
                return .localCurveBottom
            case (.localStreet, _, .localStreet, _):
                return .localCurveLeft
            case (_, .localStreet, _, .localStreet):
                return .localCurveRight
            case (.localStreet, .localStreet, _, _):
                return .localY
            case (_, _, .localStreet, .localStreet):
                return .localX
            case (_, _, _, .localStreet):
                return .localDeadEndX1
            case (_, _, .localStreet, _):
                return .localDeadEndX2
            case (_, .localStreet, _, _):
                return .localDeadEndY1
            case (.localStreet, _, _, _):
                return .localDeadEndY2
            default:
                return .localCross
        }
    }
}

enum GameMapFileChar: String {
    case localStreet = "s"
    case mainStreet = "S"
}
