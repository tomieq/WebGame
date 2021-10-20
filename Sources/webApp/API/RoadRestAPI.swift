//
//  RoadRestAPI.swift
//  
//
//  Created by Tomasz Kucharski on 20/10/2021.
//

import Foundation

class RoadRestAPI: RestAPI {
    override func setupEndpoints() {
        // MARK: openRoadInfo.js
        self.server.GET["/openRoadInfo.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/roadInfo.html?&\(address.asQueryParams)"))
            js.add(.setWindowTitle(windowIndex, title: "Road info"))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }
        
        // MARK: roadInfo.html
        self.server.GET["/roadInfo.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let address = request.mapPoint else {
                return .badRequest(.html("Invalid request! Missing address."))
            }
            
            var ownerName = "Government"
            if let road: Road = self.dataStore.find(address: address) {
                if let ownerUUID = road.ownerUUID,
                    ownerUUID != SystemPlayer.government.uuid,
                    let owner: Player = self.dataStore.find(uuid: ownerUUID) {
                    ownerName = owner.login
                }
            }

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/roadInfo.html"))
            var data = [String:String]()
            data["owner"] = ownerName
            data["tileUrl"] = TileType.street(type: .local(.localX)).image.path
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }

        // MARK: openRoadManager.js
        self.server.GET["/openRoadManager.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/roadManager.html?\(address.asQueryParams)"))
            js.add(.setWindowTitle(windowIndex, title: "Road manager"))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }
        
        // MARK: roadManager.html
        self.server.GET["/roadManager.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let address = request.mapPoint else {
                return .badRequest(.html("Invalid request! Missing address."))
            }
            
            var ownerName = SystemPlayer.government.login
            if let road: Road = self.dataStore.find(address: address) {
                if let ownerUUID = road.ownerUUID,
                    ownerUUID != SystemPlayer.government.uuid,
                    let owner: Player = self.dataStore.find(uuid: ownerUUID) {
                    ownerName = owner.login
                }
            }

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/roadInfo.html"))
            var data = [String:String]()
            data["owner"] = ownerName
            data["tileUrl"] = TileType.street(type: .local(.localX)).image.path
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
    }
}
