//
//  Graphable.swift
//
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

protocol Graphable {
    associatedtype Element: Hashable
    var description: CustomStringConvertible { get }
    func createVertex(data: Element) -> Vertex<Element>
    func add(_ type: EdgeType, from source: Vertex<Element>, to destination: Vertex<Element>, weight: Int)
    func weight(from source: Vertex<Element>, to destination: Vertex<Element>) -> Int?
    func edges(from source: Vertex<Element>) -> [Edge<Element>]?
}

public enum Visit<Element: Hashable> {
    case source
    case edge(Edge<Element>)
}

extension Graphable {
    public func route(to destination: Vertex<Element>, in tree: [Vertex<Element>: Visit<Element>]) -> [Edge<Element>] {
        var vertex = destination
        var path: [Edge<Element>] = []

        while let visit = tree[vertex], case .edge(let edge) = visit {
            path = [edge] + path
            vertex = edge.source
        }
        return path
    }

    public func distance(to destination: Vertex<Element>, in tree: [Vertex<Element>: Visit<Element>]) -> Int {
        let path = self.route(to: destination, in: tree)
        let distances = path.compactMap{ $0.weight }
        return distances.reduce(0, { $0 + $1 })
    }

    public func dijkstra(from source: Vertex<Element>, to destination: Vertex<Element>) -> [Edge<Element>]? {
        var visits: [Vertex<Element>: Visit<Element>] = [source: .source]
        var priorityQueue = PriorityQueue<Vertex<Element>>(sort: { self.distance(to: $0, in: visits) < self.distance(to: $1, in: visits) })
        priorityQueue.enqueue(source)
        while let visitedVertex = priorityQueue.dequeue() {
            if visitedVertex == destination {
                return self.route(to: destination, in: visits)
            }
            let neighbourEdges = edges(from: visitedVertex) ?? []
            for edge in neighbourEdges {
                if let weight = edge.weight {
                    if visits[edge.destination] != nil {
                        if self.distance(to: visitedVertex, in: visits) + weight < self.distance(to: edge.destination, in: visits) {
                            visits[edge.destination] = .edge(edge)
                            priorityQueue.enqueue(edge.destination)
                        }
                    } else {
                        visits[edge.destination] = .edge(edge)
                        priorityQueue.enqueue(edge.destination)
                    }
                }
            }
        }
        return nil
    }
}
