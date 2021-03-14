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
                    
                    switch dataY.value {
                        
                    case .localStreet:
                        if let streetType = self.evaluateLocalStreetType(x: dataX.key, y: dataY.key, mapMatrix: matrix) {
                            mapTiles.append(GameMapTile(x: dataX.key, y: dataY.key, image: .street(type: .local(streetType))))
                        }
                    case .mainStreet:
                        if let streetType = self.evaluateMainStreetType(x: dataX.key, y: dataY.key, mapMatrix: matrix) {
                            mapTiles.append(GameMapTile(x: dataX.key, y: dataY.key, image: .street(type: .main(streetType))))
                        }
                    case .btsAntenna:
                        mapTiles.append(GameMapTile(x: dataX.key, y: dataY.key, image: .btsAntenna))
                    case .tree1:
                        mapTiles.append(GameMapTile(x: dataX.key, y: dataY.key, image: .tree(type: 1)))
                    case .tree2:
                        mapTiles.append(GameMapTile(x: dataX.key, y: dataY.key, image: .tree(type: 2)))
                    case .tree3:
                        mapTiles.append(GameMapTile(x: dataX.key, y: dataY.key, image: .tree(type: 3)))
                    }
                    
                }
            }
        }
        return mapTiles
    }
    
    private func evaluateLocalStreetType(x: Int, y: Int, mapMatrix: MapMatrix) -> LocalStreetType? {
        let topTile = mapMatrix[x]?[y-1]
        let bottomTile = mapMatrix[x]?[y+1]
        let leftTile = mapMatrix[x-1]?[y]
        let righTile = mapMatrix[x+1]?[y]
        
        let isTopTileStreet = [.localStreet, .mainStreet].contains(topTile)
        let isBottomTileStreet = [.localStreet, .mainStreet].contains(bottomTile)
        let isLeftTileStreet = [.localStreet, .mainStreet].contains(leftTile)
        let isRightTileStreet = [.localStreet, .mainStreet].contains(righTile)
        
        switch (isTopTileStreet, isBottomTileStreet, isLeftTileStreet, isRightTileStreet) {
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
                return nil
        }
    }
    
    
    private func evaluateMainStreetType(x: Int, y: Int, mapMatrix: MapMatrix) -> MainStreetType? {
        let topTile = mapMatrix[x]?[y-1]
        let bottomTile = mapMatrix[x]?[y+1]
        let leftTile = mapMatrix[x-1]?[y]
        let righTile = mapMatrix[x+1]?[y]
        
        
        switch (topTile, bottomTile, leftTile, righTile) {
            case (.mainStreet, .mainStreet, .mainStreet, .mainStreet):
                return .mainCross

            case (.localStreet, .localStreet, .mainStreet, .mainStreet):
                return .mainXIntersection3
            case (.localStreet, .localStreet, .mainStreet, _):
                return .mainXIntersection3
            case (.localStreet, .localStreet, _, .mainStreet):
                return .mainXIntersection3

            case (.localStreet, _, .mainStreet, .mainStreet):
                return .mainXIntersection1
            case (.localStreet, _, .mainStreet, _):
                return .mainXIntersection1
            case (.localStreet, _, _, .mainStreet):
                return .mainXIntersection1

            case (_, .localStreet, .mainStreet, .mainStreet):
                return .mainXIntersection2
            case (_, .localStreet, .mainStreet, _):
                return .mainXIntersection2
            case (_, .localStreet, _, .mainStreet):
                return .mainXIntersection2
            
            case (.mainStreet, .mainStreet, .localStreet, .localStreet):
                return .mainYIntersection3
            case (.mainStreet, _, .localStreet, .localStreet):
                return .mainYIntersection3
            case (_, .mainStreet, .localStreet, .localStreet):
                return .mainYIntersection3
            
            case (.mainStreet, .mainStreet, .localStreet, _):
                return .mainYIntersection1
            case (.mainStreet, _, .localStreet, _):
                return .mainYIntersection1
            case (_, .mainStreet, .localStreet, _):
                return .mainYIntersection1

            case (.mainStreet, .mainStreet, _, .localStreet):
                return .mainYIntersection2
            case (.mainStreet, _, _, .localStreet):
                return .mainYIntersection2
            case (_, .mainStreet, _, .localStreet):
                return .mainYIntersection2

            case (.mainStreet, .mainStreet, _, _):
                return .mainY
            case (.mainStreet, _, _, _):
                return .mainY
            case (_, .mainStreet, _, _):
                return .mainY

            case (_, _, .mainStreet, .mainStreet):
                return .mainX
            case (_, _, _, .mainStreet):
                return .mainX
            case (_, _, .mainStreet, _):
                return .mainX

            default:
                return nil
        }
    }
}

enum GameMapFileChar: String {
    case localStreet = "s"
    case mainStreet = "S"
    case btsAntenna = "A"
    case tree1 = "T"
    case tree2 = "t"
    case tree3 = "d"
}
