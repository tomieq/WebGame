//
//  StreetNavi.swift
//  
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

class StreetNavi {
    let adjacencyList = AdjacencyList<MapPoint>()
    private let gameMap: GameMap
    
    init(gameMap: GameMap) {
        self.gameMap = gameMap
        // find all intersections - those are vertexes for Dijkstra's algorithm
        var vertexes = [Vertex<MapPoint>]()
        for x in (0...gameMap.width) {
            for y in (0...gameMap.height) {
                if let tile = gameMap.getTile(address: MapPoint(x: x, y: y)), tile.isVertex() {
                    Logger.info("Tile", "\(tile.address)")
                    vertexes.append(self.adjacencyList.createVertex(data: tile.address))
                }
            }
        }
        // find all edges
        vertexes.forEach { vertex in
            self.findNeighbourVertexes(for: vertex, using: self.adjacencyList, type: .directed);
        }
        
        print(self.adjacencyList.description)
    }
    
    private func findNeighbourVertexes(for vertex: Vertex<MapPoint>, using graphable: AdjacencyList<MapPoint>, type: EdgeType) {
        let vertexAddress = vertex.data
        
        var naighbourAddress = vertexAddress.move(.right)
        var distance = 1;
        while let neighbourTile = self.gameMap.getTile(address: naighbourAddress) {
            if !neighbourTile.isStreet() { break }
            if neighbourTile.isVertex() {
                graphable.add(type, from: vertex, to: graphable.createVertex(data: naighbourAddress), weight: distance)
                break
            }
            naighbourAddress = naighbourAddress.move(.right)
            distance = distance + 1
        }
        
        naighbourAddress = vertexAddress.move(.left)
        distance = 1;
        while let neighbourTile = self.gameMap.getTile(address: naighbourAddress) {
            if neighbourTile.isVertex() {
                graphable.add(type, from: vertex, to: graphable.createVertex(data: naighbourAddress), weight: distance)
                break
            }
            if !neighbourTile.isStreet() { break }
            naighbourAddress = naighbourAddress.move(.left)
            distance = distance + 1
        }
        
        naighbourAddress = vertexAddress.move(.up)
        distance = 1;
        while let neighbourTile = self.gameMap.getTile(address: naighbourAddress) {
            if neighbourTile.isVertex() {
                graphable.add(type, from: vertex, to: graphable.createVertex(data: naighbourAddress), weight: distance)
                break
            }
            if !neighbourTile.isStreet() { break }
            naighbourAddress = naighbourAddress.move(.up)
            distance = distance + 1
        }
        
        naighbourAddress = vertexAddress.move(.down)
        distance = 1;
        while let neighbourTile = self.gameMap.getTile(address: naighbourAddress) {
            if neighbourTile.isVertex() {
                graphable.add(type, from: vertex, to: graphable.createVertex(data: naighbourAddress), weight: distance)
                break
            }
            if !neighbourTile.isStreet() { break }
            naighbourAddress = naighbourAddress.move(.down)
            distance = distance + 1
        }
    }
    
    func routePoints(from startAddress: MapPoint, to stopAddress: MapPoint) -> [MapPoint]? {
        
        let naviEngine = AdjacencyList<MapPoint>()
        naviEngine.adjacencyDict = self.adjacencyList.adjacencyDict
        
        guard let startTile = self.gameMap.getTile(address: startAddress), let stopTile = self.gameMap.getTile(address: stopAddress),
            startTile.isStreet(), stopTile.isStreet() else {
                Logger.error("StreetNavi", "Navigation request rejected. Start addresses \(startAddress) --> \(stopAddress) is not a street.")
                return nil
        }
        
        [startTile, stopTile].forEach { tile in
            if !tile.isVertex() {
                let tileVertex = naviEngine.createVertex(data: tile.address)
                self.findNeighbourVertexes(for: tileVertex, using: naviEngine, type: .undirected)
            }
        }
        
        if let edges = naviEngine.dijkstra(from: naviEngine.createVertex(data: startAddress), to: naviEngine.createVertex(data: stopAddress)) {
            var points: [MapPoint] = [startAddress]
            edges.forEach { edge in
                points.append(edge.destination.data)
            }
            Logger.debug("StreetNavi", "Found the way from \(startAddress.description) to \(stopAddress.description): [ \(points.map{$0.description}.joined(separator: " --> ")) ]")
            return points
        }
        Logger.error("StreetNavi", "Couldn't find the way for route \(startAddress) --> \(stopAddress)")
        return nil
    }
}

fileprivate extension GameMapTile {
    func isVertex() -> Bool {
        switch self.type {

        case .street(let type):
            switch type {
            case .local(let subtype):
                return ![.localX, .localY].contains(subtype)
                
            case .main(let subtype):
                return ![.mainX, .mainY].contains(subtype)
            }

        default:
            return false
        }
    }
    
    func isStreet() -> Bool {
        if case .street(_) = self.type {
            return true
        }
        return false
    }
}




