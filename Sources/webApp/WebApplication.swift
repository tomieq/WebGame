//
//  WebApplication.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation
import Swifter

public class WebApplication {

    let dataStore: DataStoreProvider
    let gameEngine: GameEngine
    let api: [RestAPI]
    let propertyManagerAPI: PropertyManagerRestAPI
    
    public init(_ server: HttpServer) {
        self.dataStore = DataStoreMemoryProvider()
        self.gameEngine = GameEngine(dataStore: self.dataStore)
        self.propertyManagerAPI = PropertyManagerRestAPI(server, gameEngine: self.gameEngine)
        
        var api: [RestAPI] = []
        api.append(RoadRestAPI(server, gameEngine: self.gameEngine))
        api.append(LandRestAPI(server, gameEngine: self.gameEngine))
        api.append(PropertySalesAPI(server, gameEngine: self.gameEngine))
        api.append(ResidentialBuildingRestAPI(server, gameEngine: self.gameEngine))
        api.append(PropertyManagerRestAPI(server, gameEngine: self.gameEngine))
        api.append(PublicPlacesAPI(server, gameEngine: self.gameEngine))
        api.append(ParkingRestAPI(server, gameEngine: self.gameEngine))
        api.append(ConstructionServicesAPI(server, gameEngine: self.gameEngine))
        self.api = api

        server.GET["/"] = { request, responseHeaders in
            request.disableKeepAlive = true
            guard let userID = request.queryParam("userID"), let player: Player = self.dataStore.find(uuid: userID) else {
                    return .ok(.htmlBody("Invalid userID"))
            }
            let playerSession = PlayerSessionManager.shared.createPlayerSession(for: player)
            responseHeaders.setCookie(name: "sessionID", value: playerSession.id)
            Logger.info("WebApplication", "User \(player.login)(\(player.uuid)) started new session \(playerSession.id)")
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/pageResponse.html"))
            
            let canvasLayers = ["canvasGrass", "canvasStreets", "canvasInteraction", "canvasAddons", "canvasTraffic", "canvasBuildings"]
            let html = canvasLayers.enumerated().map { (zIndex, canvasName) in
                return Template.htmlNode(type: "canvas", attributes: ["id":canvasName,"style":"z-index:\(zIndex);"])
            }.joined(separator: "\n")
            
            var data = [String:String]()
            data["openBankTransactions"] = JSCode.openWindow(name: "Bank operations", path: "js/openBankTransactions.js", width: 500, height: 0.8, singletonID: "bankTransactions").js
            data["openWalletBalance"] = JSCode.openWindow(name: "Montly wallet balance", path: "js/openWalletBalance.js", width: 800, height: 400, singletonID: "walletBalance").js
            data["body"] = html
            data["money"] = player.wallet.money
            data["gameDate"] = self.gameEngine.time.text
            data["playerSessionID"] = playerSession.id
            template.assign(variables: data)
            return template.asResponse()
        }
        
        
        server.GET["js/init.js"] = { request, _ in
            request.disableKeepAlive = true
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/init.js"))

            var variables = [String:String]()
            variables["mapWidth"] = self.gameEngine.gameMap.width.string
            variables["mapHeight"] = self.gameEngine.gameMap.height.string
            variables["mapScale"] = self.gameEngine.gameMap.scale.string
            template.assign(variables: variables)

            return .ok(.javaScript(template.output()))
        }
        
        server.GET["js/loadMap.js"] = { request, _ in
            request.disableKeepAlive = true
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/loadMap.js"))

            for tile in self.gameEngine.gameMap.tiles {
                var variables = [String:String]()
                variables["x"] = tile.address.x.string
                variables["y"] = tile.address.y.string
                let image = tile.type.image
                variables["path"] = image.path
                variables["imageWidth"] = image.width.string
                variables["imageHeight"] = image.height.string

                if tile.isStreet() || tile.isParking() {
                    template.assign(variables: variables, inNest: "street")
                } else {
                    template.assign(variables: variables, inNest: "building")
                }
            }
            return .ok(.javaScript(template.output()))
        }
        
        server.GET["js/loadAddonsMap.js"] = { request, _ in
            request.disableKeepAlive = true
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/loadAddonsMap.js"))

            for tile in self.gameEngine.addonsMap.tiles {
                var variables = [String:String]()
                variables["x"] = tile.address.x.string
                variables["y"] = tile.address.y.string
                let image = tile.type.image
                variables["path"] = image.path
                variables["imageWidth"] = image.width.string
                variables["imageHeight"] = image.height.string

                template.assign(variables: variables, inNest: "object")
            }

            return .ok(.javaScript(template.output()))
        }
        
        server.GET["js/openBankTransactions.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            let code = JSResponse()
            code.add(.loadHtml(windowIndex, htmlPath: "bankTransactions.html"))
            return code.response
        }
        
        server.GET["bankTransactions.html"] = { request, _ in
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    return .badRequest(.text("Invalid request! Missing session ID."))
            }
            var html = ""
            let template = Template(from: "/templates/bankTransaction.html")
            for transaction in self.dataStore.getFinancialTransactions(userID: session.playerUUID) {
                var data = [String:String]()
                data["number"] = transaction.uuid
                data["date"] = GameTime(transaction.month).text
                data["title"] = transaction.title
                template.assign(variables: data)
                if transaction.amount > 0 {
                    template.assign(variables: ["money":transaction.amount.money], inNest: "income")
                } else {
                    template.assign(variables: ["money":transaction.amount.money], inNest: "cost")
                }
                html.append(template.output())
                template.reset()
            }
            return .ok(.text(html))
        }
        
        server.GET["js/openWalletBalance.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            let code = JSResponse()
            code.add(.centerWindow(windowIndex))
            code.add(.loadHtml(windowIndex, htmlPath: "walletBalance.html"))
            return code.response
        }
        
        server.GET["walletBalance.html"] = { request, _ in
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    return .badRequest(.text("Invalid request! Missing session ID."))
            }
            let template = Template.init(from: "/templates/walletBalance.html")
            /*
            for land in (Storage.shared.landProperties.filter{ $0.ownerID == session.playerUUID }) {
                
                var data: [String:String] = [:]
                data["name"] = land.name
                data["balance"] = (land.monthlyIncome - land.monthlyMaintenanceCost).money
                data["onclick"] = "mapClicked(\(land.address.x), \(land.address.y))"
                template.assign(variables: data, inNest: "investment")
            }
            
            for road in (Storage.shared.roadProperties.filter{ $0.ownerID == session.playerUUID }) {
                var data: [String:String] = [:]
                data["name"] = road.name
                data["balance"] = (road.monthlyIncome - road.monthlyMaintenanceCost).money
                data["onclick"] = "mapClicked(\(road.address.x), \(road.address.y))"
                template.assign(variables:data, inNest: "investment")
            }
            
            for building in (Storage.shared.residentialBuildings.filter{ $0.ownerID == session.playerUUID }) {
                var data: [String:String] = [:]
                data["name"] = building.name
                data["balance"] = (building.monthlyIncome - building.monthlyMaintenanceCost).money
                data["onclick"] = "mapClicked(\(building.address.x), \(building.address.y))"
                template.assign(variables: data, inNest: "investment")
            }
             */
            return .ok(.text(template.output()))
        }
        
        server.GET["js/websockets.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.queryParam("playerSessionID"), let _ = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return .ok(.text("alert('Invalid playerSessionID');"))
            }
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/websockets.js"))
            template.assign(variables: ["url":"ws://127.0.0.1:\((try? server.port()) ?? 0)/websocket", "playerSessionID": playerSessionID])
            return .ok(.javaScript(template.output()))
        }

        server["/websocket"] = websocket(text: { (session, text) in
            Logger.info("WebApplication", "Incoming message \(text)")
            self.gameEngine.websocketHandler.handleMessage(websocketSession: session, text: text)
            
        }, binary: { (session, binary) in
            session.writeBinary(binary)
        }, pong: { (_, _) in
            // Got a pong frame
        }, connected: { session in
            Logger.info("WebApplication", "New websocket client connected")
            self.gameEngine.websocketHandler.add(websocketSession: session)
        }, disconnected: { session in
            Logger.info("WebApplication", "Websocket client disconnected")
            self.gameEngine.websocketHandler.remove(websocketSession: session)
        })
        
        server.notFoundHandler = { request, responseHeaders in
            request.disableKeepAlive = true
            let filePath = Resource.absolutePath(forPublicResource: request.path)
            if FileManager.default.fileExists(atPath: filePath) {

                guard let file = try? filePath.openForReading() else {
                    Logger.error("File", "Could not open `\(filePath)`")
                    return .notFound
                }
                let mimeType = filePath.mimeType()
                responseHeaders.addHeader("Content-Type", mimeType)

                if let attr = try? FileManager.default.attributesOfItem(atPath: filePath),
                    let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                    responseHeaders.addHeader("Content-Length", String(fileSize))
                }

                return .raw(200, "OK", { writer in
                    try writer.write(file)
                    file.close()
                })
            }
            Logger.error("Unhandled request", "File `\(filePath)` doesn't exist")
            return .notFound
        }
        
        server.middleware.append { request, responseHeaders in
            Logger.info("Incoming request", "\(request.method) \(request.path)")
            return nil
        }
    }
}
