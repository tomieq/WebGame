//
//  DataStore.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

class DataStore {
    
    private static let memoryProvider = DataStoreMemoryProvider()
    
    static var provider: DataStoreProvider {
        return DataStore.memoryProvider
    }
}
