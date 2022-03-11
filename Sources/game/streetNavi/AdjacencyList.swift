//
//  AdjacencyList.swift
//
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

class AdjacencyList<T: Hashable> {
    public var adjacencyDict: [Vertex<T>: [Edge<T>]] = [:]
    public init() {}
}

extension AdjacencyList: Graphable {
    public typealias Element = T

    public func createVertex(data: Element) -> Vertex<Element> {
        let vertex = Vertex(data: data)

        if self.adjacencyDict[vertex] == nil {
            self.adjacencyDict[vertex] = []
        }
        return vertex
    }

    public func add(_ type: EdgeType, from source: Vertex<Element>, to destination: Vertex<Element>, weight: Int) {
        switch type {
        case .directed:
            self.addDirectedEdge(from: source, to: destination, weight: weight)
        case .undirected:
            self.addUndirectedEdge(vertices: (source, destination), weight: weight)
        }
    }

    fileprivate func addDirectedEdge(from source: Vertex<Element>, to destination: Vertex<Element>, weight: Int?) {
        let edge = Edge(source: source, destination: destination, weight: weight)
        self.adjacencyDict[source]?.append(edge)
    }

    fileprivate func addUndirectedEdge(vertices: (Vertex<Element>, Vertex<Element>), weight: Int?) {
        let (source, destination) = vertices
        self.addDirectedEdge(from: source, to: destination, weight: weight)
        self.addDirectedEdge(from: destination, to: source, weight: weight)
    }

    public func weight(from source: Vertex<Element>, to destination: Vertex<Element>) -> Int? {
        guard let edges = self.adjacencyDict[source] else {
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
        return self.adjacencyDict[source]
    }

    public var description: CustomStringConvertible {
        var result = ""
        for (vertex, edges) in self.adjacencyDict {
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
