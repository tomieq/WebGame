//
//  PriorityQueue.swift
//
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

public struct PriorityQueue<T> {
    fileprivate var heap: Heap<T>

    public init(sort: @escaping (T, T) -> Bool) {
        self.heap = Heap(priorityFunction: sort)
    }

    public var isEmpty: Bool {
        return self.heap.isEmpty
    }

    public var count: Int {
        return self.heap.count
    }

    public func peek() -> T? {
        return self.heap.peek()
    }

    public mutating func enqueue(_ element: T) {
        self.heap.enqueue(element)
    }

    public mutating func dequeue() -> T? {
        return self.heap.dequeue()
    }
}
