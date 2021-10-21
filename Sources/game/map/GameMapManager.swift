//
//  GameMapManager.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation

class GameMapManager {
    fileprivate typealias MapMatrix = [Int:[Int:GameMapFileEntry]]
    private var streetCache: [StreetCache] = []
    let map: GameMap
    
    init(_ map: GameMap) {
        self.map = map
    }
    
    func loadMapFrom(path: String) {
        let content = self.loadFileIntoString(path: path)
        self.loadMapFrom(content: content)
    }
    
    func loadMapFrom(content: String) {
        let matrix = self.parseStringIntoMatrix(content)
        self.initCache(matrix: matrix)
        self.map.setTiles(self.initTiles(matrix: matrix))
    }
    
    func addStreet(address: MapPoint) {
        self.streetCache.append(StreetCache(address: address, type: .localStreet))
        if let tile = self.evaluateLocalStreetMapTile(address: address) {
            self.map.replaceTile(tile: tile)
        }
        for addr in self.map.getNeighbourAddresses(to: address, radius: 1) {
            switch (self.streetCache.first { $0.address == addr}) {
                case .none:
                    break
                case .some(let obj):
                switch obj.type {
                
                case .localStreet:
                    if let tile = self.evaluateLocalStreetMapTile(address: addr) {
                        self.map.replaceTile(tile: tile)
                    }
                case .mainStreet:
                    if let tile = self.evaluateMainStreetMapTile(address: addr) {
                        self.map.replaceTile(tile: tile)
                    }
                }
            }
        }
    }
    
    func occupiedSpaceOnMap() -> Double {
        return Double(self.map.tiles.count) / Double(self.map.width * self.map.height)
    }
    
    private func loadFileIntoString(path: String) -> String {
        return (try? String(contentsOfFile: Resource.absolutePath(forAppResource: path))) ?? ""
    }
    
    private func parseStringIntoMatrix(_ content: String) -> MapMatrix {
        var matrix: MapMatrix = [:] // matrix[x][y] = "s"
        let lines = content.components(separatedBy: "\n")
        for (y, line) in lines.enumerated() {
            if y >= self.map.height { break }
            let elements = line.trimmingCharacters(in: .whitespaces).components(separatedBy: ",")
            for (x, chr) in elements.enumerated() {
                if x >= self.map.width { break }
                if matrix[x] == nil { matrix[x] = [:] }
                matrix[x]?[y] = GameMapFileEntry(rawValue: chr)
            }
        }
        return matrix
    }

    private func initCache(matrix: MapMatrix) {
        for dataX in matrix {
            for dataY in dataX.value {
                switch dataY.value {
                    case .localStreet:
                        self.streetCache.append(StreetCache(address: MapPoint(x: dataX.key, y: dataY.key), type: .localStreet))
                    case .mainStreet:
                        self.streetCache.append(StreetCache(address: MapPoint(x: dataX.key, y: dataY.key), type: .mainStreet))
                    default:
                        break
                }
            }
        }
    }

    private func initTiles(matrix: MapMatrix) -> [GameMapTile] {
        var mapTiles: [GameMapTile] = []
        for dataX in matrix {
            for dataY in dataX.value {
                
                switch dataY.value {
                    
                case .localStreet:
                    if let tile = self.evaluateLocalStreetMapTile(address: MapPoint(x: dataX.key, y: dataY.key)) {
                        mapTiles.append(tile)
                    }
                case .mainStreet:
                    if let tile = self.evaluateMainStreetMapTile(address: MapPoint(x: dataX.key, y: dataY.key)) {
                        mapTiles.append(tile)
                    }
                case .streetUnderConstruction:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .streetUnderConstruction))
                case .btsAntenna:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .btsAntenna))
                case .cityCouncil:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .cityCouncil))
                case .warehouse:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .warehouse))
                case .building4:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .building(size: 4)))
                case .building6:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .building(size: 6)))
                case .building8:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .building(size: 8)))
                case .building10:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .building(size: 10)))
                case .tree1:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .tree(type: 1)))
                case .tree2:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .tree(type: 2)))
                case .tree3:
                    mapTiles.append(GameMapTile(address: MapPoint(x: dataX.key, y: dataY.key), type: .tree(type: 3)))
                }
                
            }
        }

        return mapTiles
    }
    
    private func wrap(_ address: MapPoint, _ streetType: StreetType) -> GameMapTile {
        return GameMapTile(address: address, type: .street(type: streetType))
    }
    
    private func evaluateLocalStreetMapTile(address: MapPoint) -> GameMapTile? {
        let topTile = address.move(.up)
        let bottomTile = address.move(.down)
        let leftTile = address.move(.left)
        let righTile = address.move(.right)
        
        let isTopTileStreet = self.streetCache.first { $0.address == topTile } != nil
        let isBottomTileStreet = self.streetCache.first { $0.address == bottomTile } != nil
        let isLeftTileStreet = self.streetCache.first { $0.address == leftTile } != nil
        let isRightTileStreet = self.streetCache.first { $0.address == righTile } != nil
        
        switch (isTopTileStreet, isBottomTileStreet, isLeftTileStreet, isRightTileStreet) {
            case (true, true, true, true):
                return self.wrap(address, .local(.localCross))
            case (true, true, true, false):
                return self.wrap(address, .local(.localYIntersection1))
            case (true, true, false, true):
                return self.wrap(address, .local(.localYIntersection2))
            case (false, true, true, true):
                return self.wrap(address, .local(.localXIntersection2))
            case (true, false, true, true):
                return self.wrap(address, .local(.localXIntersection1))
            case (true, false, false, true):
                return self.wrap(address, .local(.localCurveTop))
            case (false, true, true, false):
                return self.wrap(address, .local(.localCurveBottom))
            case (true, false, true, false):
                return self.wrap(address, .local(.localCurveLeft))
            case (false, true, false, true):
                return self.wrap(address, .local(.localCurveRight))
            case (true, true, false, false):
                return self.wrap(address, .local(.localY))
            case (false, false, true, true):
                return self.wrap(address, .local(.localX))
            case (false, false, false, true):
                return self.wrap(address, .local(.localDeadEndX1))
            case (false, false, true, false):
                return self.wrap(address, .local(.localDeadEndX2))
            case (false, true, false, false):
                return self.wrap(address, .local(.localDeadEndY1))
            case (true, false, false, false):
                return self.wrap(address, .local(.localDeadEndY2))
            default:
                return nil
        }
    }
    
    private func evaluateMainStreetMapTile(address: MapPoint) -> GameMapTile? {
        let topTile = self.streetCache.first{ $0.address == address.move(.up) }?.type
        let bottomTile = self.streetCache.first{ $0.address == address.move(.down) }?.type
        let leftTile = self.streetCache.first{ $0.address == address.move(.left) }?.type
        let righTile = self.streetCache.first{ $0.address == address.move(.right) }?.type
        
        
        switch (topTile, bottomTile, leftTile, righTile) {
            case (.mainStreet, .mainStreet, .mainStreet, .mainStreet):
                return self.wrap(address, .main(.mainCross))

            case (.localStreet, .localStreet, .mainStreet, .mainStreet):
                return self.wrap(address, .main(.mainXIntersection3))
            case (.localStreet, .localStreet, .mainStreet, _):
                return self.wrap(address, .main(.mainXIntersection3))
            case (.localStreet, .localStreet, _, .mainStreet):
                return self.wrap(address, .main(.mainXIntersection3))

            case (.localStreet, _, .mainStreet, .mainStreet):
                return self.wrap(address, .main(.mainXIntersection1))
            case (.localStreet, _, .mainStreet, _):
                return self.wrap(address, .main(.mainXIntersection1))
            case (.localStreet, _, _, .mainStreet):
                return self.wrap(address, .main(.mainXIntersection1))

            case (_, .localStreet, .mainStreet, .mainStreet):
                return self.wrap(address, .main(.mainXIntersection2))
            case (_, .localStreet, .mainStreet, _):
                return self.wrap(address, .main(.mainXIntersection2))
            case (_, .localStreet, _, .mainStreet):
                return self.wrap(address, .main(.mainXIntersection2))
            
            case (.mainStreet, .mainStreet, .localStreet, .localStreet):
                return self.wrap(address, .main(.mainYIntersection3))
            case (.mainStreet, _, .localStreet, .localStreet):
                return self.wrap(address, .main(.mainYIntersection3))
            case (_, .mainStreet, .localStreet, .localStreet):
                return self.wrap(address, .main(.mainYIntersection3))
            
            case (.mainStreet, .mainStreet, .localStreet, _):
                return self.wrap(address, .main(.mainYIntersection1))
            case (.mainStreet, _, .localStreet, _):
                return self.wrap(address, .main(.mainYIntersection1))
            case (_, .mainStreet, .localStreet, _):
                return self.wrap(address, .main(.mainYIntersection1))

            case (.mainStreet, .mainStreet, _, .localStreet):
                return self.wrap(address, .main(.mainYIntersection2))
            case (.mainStreet, _, _, .localStreet):
                return self.wrap(address, .main(.mainYIntersection2))
            case (_, .mainStreet, _, .localStreet):
                return self.wrap(address, .main(.mainYIntersection2))

            case (.mainStreet, .mainStreet, _, _):
                return self.wrap(address, .main(.mainY))
            case (.mainStreet, _, _, _):
                return self.wrap(address, .main(.mainY))
            case (_, .mainStreet, _, _):
                return self.wrap(address, .main(.mainY))

            case (_, _, .mainStreet, .mainStreet):
                return self.wrap(address, .main(.mainX))
            case (_, _, _, .mainStreet):
                return self.wrap(address, .main(.mainX))
            case (_, _, .mainStreet, _):
                return self.wrap(address, .main(.mainX))

            default:
                return nil
        }
    }
}

fileprivate enum GameMapFileEntry: String {
    case localStreet = "s"
    case streetUnderConstruction = "u"
    case mainStreet = "S"
    case btsAntenna = "A"
    case building4 = "b"
    case building6 = "B"
    case building8 = "r"
    case building10 = "R"
    case cityCouncil = "C"
    case tree1 = "T"
    case tree2 = "t"
    case tree3 = "d"
    case warehouse = "w"
}

fileprivate enum RoadType {
    case localStreet
    case mainStreet
}

fileprivate struct StreetCache {
    let address: MapPoint
    let type: RoadType
}
