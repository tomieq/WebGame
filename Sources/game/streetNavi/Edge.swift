//
//  Edge.swift
//
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

public enum EdgeType {
    case directed
    case undirected
}

public struct Edge<T: Hashable> {
    public var source: Vertex<T>
    public var destination: Vertex<T>
    public let weight: Int?
}

extension Edge: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.source)
        hasher.combine(self.destination)
        hasher.combine(self.weight)
    }

    static public func == (lhs: Edge<T>, rhs: Edge<T>) -> Bool {
        return lhs.source == rhs.source && lhs.destination == rhs.destination && lhs.weight == rhs.weight
    }
}
