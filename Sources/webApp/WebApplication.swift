//
//  WebApplication.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation
import Swifter

class WebApplication {

    let gameMap = GameMap(width: 25, height: 25, scale: 0.35, path: "maps/roadMap1")
    let streetNavi: StreetNavi
    
    init(_ server: HttpServer) {

        self.streetNavi = StreetNavi(gameMap: self.gameMap)
        
        server.GET["/"] = { request, _ in
            let rawPage = Resource.getAppResource(relativePath: "templates/pageResponse.html")
            let template = Template(raw: rawPage)
            
            let canvasLayers = ["canvasStreets", "canvasInteraction", "canvasTraffic", "canvasBuildings"]
            let html = canvasLayers.enumerated().map { (zIndex, canvasName) in
                return Template.htmlNode(type: "canvas", attributes: ["id":canvasName,"style":"z-index:\(zIndex);"])
            }.joined(separator: "\n")
            
            template.set(variables: ["body": html])
            return template.asResponse()
        }
        
        
        server.GET["js/init.js"] = { request, responseHeaders in
            responseHeaders.addHeader("Content-Type", "text/javascript;charset=UTF-8")
            let raw = Resource.getAppResource(relativePath: "templates/init.js")
            let template = Template(raw: raw)
            
            
            var variables = [String:String]()
            variables["mapWidth"] = self.gameMap.width.string
            variables["mapHeight"] = self.gameMap.height.string
            variables["mapScale"] = self.gameMap.scale.string
            template.set(variables: variables)

            
            return .ok(.text(template.output()))
        }
        
        server.GET["js/loadMap.js"] = { request, responseHeaders in
            responseHeaders.addHeader("Content-Type", "text/javascript;charset=UTF-8")
            let raw = Resource.getAppResource(relativePath: "templates/loadMap.js")
            let template = Template(raw: raw)
            
            self.gameMap.tiles.forEach { tile in
                var variables = [String:String]()
                variables["x"] = tile.address.x.string
                variables["y"] = tile.address.y.string
                variables["path"] = tile.type.image.path
                variables["imageWidth"] = tile.type.image.width.string
                variables["imageHeight"] = tile.type.image.height.string
                
                if case .street(_) = tile.type {
                    template.set(variables: variables, inNest: "street")
                } else {
                    template.set(variables: variables, inNest: "building")
                }
            }
            
            if let routePoints = self.streetNavi.routePoints(from: MapPoint(x: 0, y: 16), to: MapPoint(x: 22, y: 2)) {
                var variables = [String:String]()
                variables["points"] = routePoints.map{ "new MapPoint(\($0.x), \($0.y))" }.joined(separator: ", ")
                variables["id"] = "897"
                variables["speed"] = "7"
                variables["type"] = "truck1"
                template.set(variables: variables, inNest: "traffic")
            }
            if let routePoints = self.streetNavi.routePoints(from: MapPoint(x: 17, y: 22), to: MapPoint(x: 0, y: 3)) {
                var variables = [String:String]()
                variables["points"] = routePoints.map{ "new MapPoint(\($0.x), \($0.y))" }.joined(separator: ", ")
                variables["id"] = "898"
                variables["speed"] = "7"
                variables["type"] = "car2"
                template.set(variables: variables, inNest: "traffic")
            }
            
            return .ok(.text(template.output()))
        }
        
        
        server.GET["js/websockets.js"] = { request, responseHeaders in
            responseHeaders.addHeader("Content-Type", "text/javascript;charset=UTF-8")
            let raw = Resource.getAppResource(relativePath: "templates/websockets.js")
            let template = Template(raw: raw)
            template.set(variables: ["url":"ws://localhost:5920/websocket"])
            return .ok(.text(template.output()))
        }

        server["/websocket"] = websocket(text: { (session, text) in
            Logger.info("WebApplication", "Incoming message \(text)")
            if let data = text.data(using: .utf8),
                let jsonData = try? JSONDecoder().decode(BackendAnonymouseCommand.self, from: data),
                let command = jsonData.command {
                
                Logger.info("DBG", "Incomming websocket command \(command)")
                switch command {
                case .tileClicked:
                    if let backendCommand = try? JSONDecoder().decode(BackendCommand<MapPoint>.self, from: data),
                        let point = backendCommand.data {
                        if let routePoints = self.streetNavi.routePoints(from: MapPoint(x: 0, y: 16), to: point) {
                            let command = FrontEndCommand(StartVehicleDto())
                            command.command = .startVehicle
                            command.data.points = routePoints
                            let json = command.toJSONString() ?? ""
                            session.writeText(json)
                            Logger.info("WebApplication", "Outgoing message \(json)")
                        }
                    }
                }
            }
            
            
        }, binary: { (session, binary) in
            session.writeBinary(binary)
        }, pong: { (_, _) in
            // Got a pong frame
        }, connected: { _ in
            Logger.info("WebApplication", "New websocket client connected")
        }, disconnected: { _ in
            Logger.info("WebApplication", "Websocket client disconnected")
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
