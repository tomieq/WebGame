//
//  RoadRestAPI.swift
//
//
//  Created by Tomasz Kucharski on 20/10/2021.
//

import Foundation

class RoadRestAPI: RestAPI {
    override func setupEndpoints() {
        // MARK: openRoadInfo
        self.server.get[.openRoadInfo] = { request, _ in
            

            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.openWindow(name: "Road info", path: "/initRoadInfo.js".append(address), width: 400, height: 250, point: address, singletonID: address.asQueryParams))
            return js.response
        }

        // MARK: initRoadInfo.js
        self.server.get["/initRoadInfo.js"] = { request, _ in
            
            guard let windowIndex = request.windowIndex else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/roadInfo.html".append(address)))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }

        // MARK: roadInfo.html
        self.server.get["/roadInfo.html"] = { request, _ in
            
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }

            var ownerName = "Government"
            if let road: Road = self.dataStore.find(address: address) {
                if road.ownerUUID != SystemPlayer.government.uuid,
                   let owner: Player = self.dataStore.find(uuid: road.ownerUUID) {
                    ownerName = owner.login
                }
            }

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/roadInfo.html"))
            var data = [String: String]()
            data["owner"] = ownerName
            data["tileUrl"] = TileType.street(type: .local(.localX)).image.path
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }

        // MARK: openRoadManager
        self.server.get[.openRoadManager] = { request, _ in
            

            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.openWindow(name: "Road manager", path: "/initRoadManager.js".append(address), width: 0.7, height: 250, point: address, singletonID: address.asQueryParams))
            return js.response
        }

        // MARK: initRoadManager.js
        self.server.get["/initRoadManager.js"] = { request, _ in
            
            guard let windowIndex = request.windowIndex else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/roadManager.html".append(address)))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }

        // MARK: roadManager.html
        self.server.get["/roadManager.html"] = { request, _ in
            
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }

            guard let playerSessionID = request.playerSessionID,
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return self.htmlError("Invalid request! Missing sessionID.")
            }

            guard let road: Road = self.dataStore.find(address: address),
                  road.ownerUUID == session.playerUUID else {
                return self.htmlError("You are not allowed to manage this road")
            }

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/roadManager.html"))
            var data = [String: String]()
            data["tileUrl"] = TileType.street(type: .local(.localX)).image.path
            data["name"] = road.name
            data["type"] = road.type
            data["purchasePrice"] = road.purchaseNetValue.money
            data["investmentsValue"] = road.investmentsNetValue.money

            let monthlyCosts = self.gameEngine.propertyBalanceCalculator.getMontlyCosts(address: address)

            for cost in monthlyCosts {
                var data: [String: String] = [:]
                data["name"] = cost.title
                data["netValue"] = cost.netValue.money
                data["taxRate"] = (cost.taxRate * 100).rounded(toPlaces: 0).string
                data["taxValue"] = cost.tax.money
                data["total"] = cost.total.money
                template.assign(variables: data, inNest: "cost")
            }
            if monthlyCosts.count > 0 {
                var data: [String: String] = [:]
                data["netValue"] = monthlyCosts.map{ $0.netValue }.reduce(0, +).money
                data["taxValue"] = monthlyCosts.map{ $0.tax }.reduce(0, +).money
                data["total"] = monthlyCosts.map{ $0.total }.reduce(0, +).money
                template.assign(variables: data, inNest: "costTotal")
            }

            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
    }
}
