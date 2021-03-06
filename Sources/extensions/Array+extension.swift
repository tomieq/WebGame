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
            remove(at: index)
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
            guard index >= 0 && index < self.count else { return nil }
            return self[index]
        }
        
        set(newValue) {
            guard let value = newValue, index >= 0 && index < self.count else { return }
            self[index] = value
        }
    }
    
}
