//
//  StreetNavi.swift
//  
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

class StreetNavi {
    let adjacencyList = AdjacencyList<MapPoint>()
    
    init(gameMap: GameMap) {
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
            let vertexAddress = vertex.data
            
            var naighbourAddress = vertexAddress.moveRight()
            var distance = 1;
            while let neighbourTile = gameMap.getTile(address: naighbourAddress) {
                if !neighbourTile.isStreet() { break }
                if neighbourTile.isVertex() {
                    self.adjacencyList.add(from: vertex, to: self.adjacencyList.createVertex(data: naighbourAddress), weight: distance)
                    break
                }
                naighbourAddress = naighbourAddress.moveRight()
                distance = distance + 1
            }
            
            naighbourAddress = vertexAddress.moveLeft()
            distance = 1;
            while let neighbourTile = gameMap.getTile(address: naighbourAddress) {
                if neighbourTile.isVertex() {
                    self.adjacencyList.add(from: vertex, to: self.adjacencyList.createVertex(data: naighbourAddress), weight: distance)
                    break
                }
                if !neighbourTile.isStreet() { break }
                naighbourAddress = naighbourAddress.moveLeft()
                distance = distance + 1
            }
            
            naighbourAddress = vertexAddress.moveUp()
            distance = 1;
            while let neighbourTile = gameMap.getTile(address: naighbourAddress) {
                if neighbourTile.isVertex() {
                    self.adjacencyList.add(from: vertex, to: self.adjacencyList.createVertex(data: naighbourAddress), weight: distance)
                    break
                }
                if !neighbourTile.isStreet() { break }
                naighbourAddress = naighbourAddress.moveUp()
                distance = distance + 1
            }
            
            naighbourAddress = vertexAddress.moveDown()
            distance = 1;
            while let neighbourTile = gameMap.getTile(address: naighbourAddress) {
                if neighbourTile.isVertex() {
                    self.adjacencyList.add(from: vertex, to: self.adjacencyList.createVertex(data: naighbourAddress), weight: distance)
                    break
                }
                if !neighbourTile.isStreet() { break }
                naighbourAddress = naighbourAddress.moveDown()
                distance = distance + 1
            }
        }
        
        print(self.adjacencyList.description)
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




