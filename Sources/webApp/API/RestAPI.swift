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
    
    func jsError(_ text: String) -> HttpResponse {
        return JSCode.showError(txt: text, duration: 10).response
    }
    
    func htmlError(_ text: String) -> HttpResponse {
        let template = Template(raw: ResourceCache.shared.getAppResource("templates/error.html"))
        template.assign(variables: ["text": text])
        return template.asResponse()
    }
}
