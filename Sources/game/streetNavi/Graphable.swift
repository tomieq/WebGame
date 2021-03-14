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
    func add(from source: Vertex<Element>, to destination: Vertex<Element>, weight: Int)
    func weight(from source: Vertex<Element>, to destination: Vertex<Element>) -> Int?
    func edges(from source: Vertex<Element>) -> [Edge<Element>]?
}
