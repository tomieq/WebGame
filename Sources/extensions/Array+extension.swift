//
//  Array+extension.swift
//
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

extension Array where Element: Equatable {
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = firstIndex(of: object) {
            self.remove(at: index)
        }
    }
}

extension Array {
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

extension Array {
    func count(match: (Element) -> Bool) -> Int {
        var count: Int = 0
        for x in self {
            if match(x) {
                count = count + 1
            }
        }
        return count
    }

    func contains(match: (Element) -> Bool) -> Bool {
        for x in self {
            if match(x) {
                return true
            }
        }
        return false
    }

    subscript(safeIndex index: Int) -> Element? {
        get {
            guard index >= 0, index < self.count else { return nil }
            return self[index]
        }

        set(newValue) {
            guard let value = newValue, index >= 0, index < self.count else { return }
            self[index] = value
        }
    }
}

extension Array where Element: Equatable {
    var unique: [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            guard !uniqueValues.contains(item) else { return }
            uniqueValues.append(item)
        }
        return uniqueValues
    }
}
