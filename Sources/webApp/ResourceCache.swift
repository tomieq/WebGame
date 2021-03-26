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
    
    private init() {
        self.cache = [:]
    }
    
    func getAppResource(_ relativePath: String) -> String {
        if let content = self.cache[relativePath] {
            return content
        }
        self.cache[relativePath] = Resource.getAppResource(relativePath: relativePath)
        return self.cache[relativePath]!
    }
}
