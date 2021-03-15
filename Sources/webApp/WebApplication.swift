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
            
            var html = Template.htmlNode(type: "canvas", attributes: ["id":"canvasStreets","style":"z-index:0;"])
            html.append(Template.htmlNode(type: "canvas", attributes: ["id":"canvasTraffic","style":"z-index:1;"]))
            html.append(Template.htmlNode(type: "canvas", attributes: ["id":"canvasBuildings","style":"z-index:2;"]))
            
            
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
            return .ok(.text(template.output()))
        }

        server["/websocket"] = websocket(text: { (session, text) in
            session.writeText(text)
            Logger.info("WebApplication", "Incoming message \(text)")
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
