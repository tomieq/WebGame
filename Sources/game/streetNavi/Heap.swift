//
//  Heap.swift
//
//
//  Created by Tomasz Kucharski on 14/03/2021.
//

import Foundation

struct Heap<Element> {
    var elements: [Element]
    let priorityFunction: (Element, Element) -> Bool

    init(elements: [Element] = [], priorityFunction: @escaping (Element, Element) -> Bool) {
        self.elements = elements
        self.priorityFunction = priorityFunction
        self.buildHeap()
    }

    mutating func buildHeap() {
        for index in (0..<self.count / 2).reversed() {
            self.siftDown(elementAtIndex: index)
        }
    }

    var isEmpty: Bool { return self.elements.isEmpty }
    var count: Int { return self.elements.count }

    func peek() -> Element? {
        return self.elements.first
    }

    mutating func enqueue(_ element: Element) {
        self.elements.append(element)
        self.siftUp(elementAtIndex: self.count - 1)
    }

    mutating func siftUp(elementAtIndex index: Int) {
        let parent = self.parentIndex(of: index)
        guard !self.isRoot(index),
              self.isHigherPriority(at: index, than: parent) else { return }
        self.swapElement(at: index, with: parent)
        self.siftUp(elementAtIndex: parent)
    }

    mutating func dequeue() -> Element? {
        guard !self.isEmpty else { return nil }
        self.swapElement(at: 0, with: self.count - 1)
        let element = self.elements.removeLast()
        if !self.isEmpty {
            self.siftDown(elementAtIndex: 0)
        }
        return element
    }

    mutating func siftDown(elementAtIndex index: Int) {
        let childIndex = self.highestPriorityIndex(for: index)
        if index == childIndex {
            return
        }
        self.swapElement(at: index, with: childIndex)
        self.siftDown(elementAtIndex: childIndex)
    }

    // Helper functions

    func isRoot(_ index: Int) -> Bool {
        return index == 0
    }

    func leftChildIndex(of index: Int) -> Int {
        return (2 * index) + 1
    }

    func rightChildIndex(of index: Int) -> Int {
        return (2 * index) + 2
    }

    func parentIndex(of index: Int) -> Int {
        return (index - 1) / 2
    }

    func isHigherPriority(at firstIndex: Int, than secondIndex: Int) -> Bool {
        return self.priorityFunction(self.elements[firstIndex], self.elements[secondIndex])
    }

    func highestPriorityIndex(of parentIndex: Int, and childIndex: Int) -> Int {
        guard childIndex < self.count, self.isHigherPriority(at: childIndex, than: parentIndex) else { return parentIndex }
        return childIndex
    }

    func highestPriorityIndex(for parent: Int) -> Int {
        return self.highestPriorityIndex(of: self.highestPriorityIndex(of: parent, and: self.leftChildIndex(of: parent)), and: self.rightChildIndex(of: parent))
    }

    mutating func swapElement(at firstIndex: Int, with secondIndex: Int) {
        guard firstIndex != secondIndex else { return }
        self.elements.swapAt(firstIndex, secondIndex)
    }
}

extension Heap where Element: Equatable {
    // This function allows you to remove an element from the heap, in a similar way to how you would dequeue the root element.
    mutating func remove(_ element: Element) {
        guard let index = elements.index(of: element) else { return }
        self.swapElement(at: index, with: self.count - 1)
        self.elements.remove(at: self.count - 1)
        self.siftDown(elementAtIndex: index)
    }

    // This function allows you to 'boost' an element, by sifting the element up the heap. You might do this if the element is already in the heap, but its priority has increased since it was enqueued.
    mutating func boost(_ element: Element) {
        guard let index = elements.index(of: element) else { return }
        self.siftUp(elementAtIndex: index)
    }
}
