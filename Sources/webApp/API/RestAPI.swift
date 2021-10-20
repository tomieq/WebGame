//
//  RestAPI.swift
//  
//
//  Created by Tomasz Kucharski on 20/10/2021.
//

import Foundation
import Swifter

class RestAPI {
    
    let gameEngine: GameEngine
    let dataStore: DataStoreProvider
    let server: HttpServer
    
    init(_ server: HttpServer, gameEngine: GameEngine) {
        
        self.gameEngine = gameEngine
        self.dataStore = gameEngine.dataStore
        self.server = server
        self.setupEndpoints()
    }
    
    func setupEndpoints() {
        
    }
    
}
