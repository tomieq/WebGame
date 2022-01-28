//
//  ResourceCache.swift
//  
//
//  Created by Tomasz Kucharski on 26/03/2021.
//

import Foundation

class ResourceCache {
    public static let shared = ResourceCache()
    
    private var cache: [String:String]
    private let caching = false
    
    private init() {
        self.cache = [:]
    }
    
    func getAppResource(_ relativePath: String) -> String {
        guard self.caching else { return Resource.getAppResource(relativePath: relativePath) }
        if let content = self.cache[relativePath] {
            return content
        }
        self.cache[relativePath] = Resource.getAppResource(relativePath: relativePath)
        return self.cache[relativePath]!
    }
}
