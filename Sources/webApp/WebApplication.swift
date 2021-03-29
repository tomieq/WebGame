//
//  WebApplication.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation
import Swifter

class WebApplication {

    let gameEngine = GameEngine()
    let propertyManagerAPI: PropertyManagerRestAPI
    
    init(_ server: HttpServer) {
        
        self.propertyManagerAPI = PropertyManagerRestAPI(server, gameEngine: self.gameEngine)

        server.GET["/"] = { request, responseHeaders in
            request.disableKeepAlive = true
            guard let userID = request.queryParam("userID"), let player = (Storage.shared.players.first{ $0.id == userID }) else {
                    return .ok(.htmlBody("Invalid userID"))
            }
            let playerSession = PlayerSessionManager.shared.createPlayerSession(for: player)
            responseHeaders.setCookie(name: "sessionID", value: playerSession.id)
            Logger.info("WebApplication", "User \(player.login)(\(player.id)) started new session \(playerSession.id)")
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/pageResponse.html"))
            
            let canvasLayers = ["canvasStreets", "canvasInteraction", "canvasTraffic", "canvasBuildings"]
            let html = canvasLayers.enumerated().map { (zIndex, canvasName) in
                return Template.htmlNode(type: "canvas", attributes: ["id":canvasName,"style":"z-index:\(zIndex);"])
            }.joined(separator: "\n")
            
            let now = GameDate(monthIteration: Storage.shared.monthIteration)
            
            var data = [String:String]()
            data["openBankTransactions"] = JSCode.openWindow(name: "Bank operations", path: "js/openBankTransactions.js", width: 500, height: 0.8).js
            data["body"] = html
            data["money"] = player.wallet.money
            data["gameDate"] = now.text
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

                if tile.isStreet() {
                    template.assign(variables: variables, inNest: "street")
                } else {
                    template.assign(variables: variables, inNest: "building")
                }
            }
            return .ok(.javaScript(template.output()))
        }
        
        
        server.GET["js/websockets.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.queryParam("playerSessionID"), let _ = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return .ok(.text("alert('Invalid playerSessionID');"))
            }
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/websockets.js"))
            template.assign(variables: ["url":"ws://192.168.88.50:5920/websocket", "playerSessionID": playerSessionID])
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
                    return .ok(.text("Invalid request! Missing session ID."))
            }
            var html = ""
            let template = Template.init(from: "/templates/bankTransaction.html")
            for transaction in (Storage.shared.transactionArchive.filter{ $0.playerID == session.player.id }) {
                var data = [String:String]()
                data["number"] = transaction.id.string
                data["date"] = GameDate(monthIteration: transaction.monthIteration).text
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
