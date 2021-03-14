//
//  AdjacencyList.swift
//  
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

class AdjacencyList<T: Hashable> {
    public var adjacencyDict : [Vertex<T>: [Edge<T>]] = [:]
    public init() {}
}

extension AdjacencyList: Graphable {
    public typealias Element = T
    
    public func createVertex(data: Element) -> Vertex<Element> {
        let vertex = Vertex(data: data)
      
        if adjacencyDict[vertex] == nil {
            adjacencyDict[vertex] = []
        }
        return vertex
    }

    public func add(from source: Vertex<Element>, to destination: Vertex<Element>, weight: Int) {
        let edge = Edge(source: source, destination: destination, weight: weight)
        adjacencyDict[source]?.append(edge)
    }

    public func weight(from source: Vertex<Element>, to destination: Vertex<Element>) -> Int? {
        guard let edges = adjacencyDict[source] else {
            return nil
        }
      
        for edge in edges {
            if edge.destination == destination {
                return edge.weight
            }
        }
      
        return nil
    }
    
    public func edges(from source: Vertex<Element>) -> [Edge<Element>]? {
        return adjacencyDict[source]
    }
    
    public var description: CustomStringConvertible {
        var result = ""
        for (vertex, edges) in adjacencyDict {
            var edgeString = ""
            for (index, edge) in edges.enumerated() {
                if index != edges.count - 1 {
                    edgeString.append("\(edge.destination), ")
                } else {
                    edgeString.append("\(edge.destination)")
                }
            }
            result.append("\(vertex) ---> [ \(edgeString) ] \n ")
        }
        return result
    }
}


