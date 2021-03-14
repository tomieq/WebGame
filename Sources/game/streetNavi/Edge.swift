//
//  Edge.swift
//  
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

public struct Edge<T: Hashable> {
    public var source: Vertex<T>
    public var destination: Vertex<T>
    public let weight: Int?
}

extension Edge: Hashable {
  
    public var hashValue: Int {
        return "\(source)\(destination)\(weight)".hashValue
    }
  
    static public func ==(lhs: Edge<T>, rhs: Edge<T>) -> Bool {
        return lhs.source == rhs.source && lhs.destination == rhs.destination && lhs.weight == rhs.weight
  }
}
