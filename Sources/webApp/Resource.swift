//
//  Resource.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation

class Resource {
    private static let appResourcesDir = FileManager.default.currentDirectoryPath + "/AppResources/"
    private static let publicResourcesPath = FileManager.default.currentDirectoryPath + "/PublicResources/"
    
    
    static func getAppResource(relativePath: String) -> String {
        let url = URL(fileURLWithPath: Resource.absolutePath(forAppResource: relativePath))
        do {
            Logger.info("Resource", "Loading \(relativePath)")
            return try String(contentsOf: url)
        } catch {
            Logger.error("Resource", "Error loading app resource from \(url.absoluteString)")
        }
        return ""
    }
    
    static func absolutePath(forPublicResource relativePath: String) -> String {
        return Resource.publicResourcesDir + relativePath.trimmingCharacters(in: CharacterSet(arrayLiteral: "/"))
    }
    
    static func absolutePath(forAppResource relativePath: String) -> String {
        return Resource.appResourcesDir + relativePath.trimmingCharacters(in: CharacterSet(arrayLiteral: "/"))
    }
}
