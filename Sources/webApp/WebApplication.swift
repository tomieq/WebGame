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
            
            guard let userID = request.queryParam("userID"), let player = (Storage.shared.players.first{ $0.id == userID }) else {
                    return .ok(.htmlBody("Invalid userID"))
            }
            let playerSession = PlayerSessionManager.shared.createPlayerSession(for: player)
            responseHeaders.setCookie(name: "sessionID", value: playerSession.id)
            Logger.info("WebApplication", "User \(player.login)(\(player.id)) started new session \(playerSession.id)")
            
            let rawPage = Resource.getAppResource(relativePath: "templates/pageResponse.html")
            let template = Template(raw: rawPage)
            
            let canvasLayers = ["canvasStreets", "canvasInteraction", "canvasTraffic", "canvasBuildings"]
            var html = canvasLayers.enumerated().map { (zIndex, canvasName) in
                return Template.htmlNode(type: "canvas", attributes: ["id":canvasName,"style":"z-index:\(zIndex);"])
            }.joined(separator: "\n")
            html.append(Template.htmlNode(type: "div", attributes: ["id":"wallet"], content: "$ 1 000 000"))
            let calendarIcon = Template.htmlNode(type: "i", attributes: ["class":"fa fa-calendar"], content: "")
            let now = GameDate(monthIteration: Storage.shared.monthIteration)
            let calendarContent = Template.htmlNode(type: "span", attributes: ["id":"gameDate"], content: "\(now.month)/\(now.year)")
            html.append(Template.htmlNode(type: "div", attributes: ["id":"gameClock"], content: "\(calendarIcon) \(calendarContent)"))
            
            template.assign(variables: ["body": html, "playerSessionID": playerSession.id])
            return template.asResponse()
        }
        
        
        server.GET["js/init.js"] = { request, _ in
            let raw = Resource.getAppResource(relativePath: "templates/init.js")
            let template = Template(raw: raw)

            var variables = [String:String]()
            variables["mapWidth"] = self.gameEngine.gameMap.width.string
            variables["mapHeight"] = self.gameEngine.gameMap.height.string
            variables["mapScale"] = self.gameEngine.gameMap.scale.string
            template.assign(variables: variables)

            return .ok(.javaScript(template.output()))
        }
        
        server.GET["js/loadMap.js"] = { request, _ in

            let raw = Resource.getAppResource(relativePath: "templates/loadMap.js")
            let template = Template(raw: raw)

            self.gameEngine.gameMap.tiles.forEach { tile in
                var variables = [String:String]()
                variables["x"] = tile.address.x.string
                variables["y"] = tile.address.y.string
                variables["path"] = tile.type.image.path
                variables["imageWidth"] = tile.type.image.width.string
                variables["imageHeight"] = tile.type.image.height.string

                if case .street(_) = tile.type {
                    template.assign(variables: variables, inNest: "street")
                } else {
                    template.assign(variables: variables, inNest: "building")
                }
            }
            return .ok(.javaScript(template.output()))
        }
        
        
        server.GET["js/websockets.js"] = { request, _ in

            guard let playerSessionID = request.queryParam("playerSessionID"), let _ = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return .ok(.text("alert('Invalid playerSessionID');"))
            }
            let raw = Resource.getAppResource(relativePath: "templates/websockets.js")
            let template = Template(raw: raw)
            template.assign(variables: ["url":"ws://192.168.88.50:5920/websocket", "playerSessionID": playerSessionID])
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
