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
    
    init(_ server: HttpServer) {
        
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
            html.append(Template.htmlNode(type: "div", attributes: ["id":"wallet"], content: "$ 1000 000"))
            
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

            self.gameEngine.gameMap.gameTiles.forEach { tile in
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
        
        server.GET["/openSaleOffer.js"] = { request, _ in
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            guard self.gameEngine.realEstateAgent.isForSale(address: address) else {
                return JSCode.showError(txt: "This property is not for sale", duration: 10).response
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/saleOffer.html?\(address.asQueryParams)"))
            js.add(.setWindowTitle(windowIndex, title: "Land property"))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }
        
        server.GET["/saleOffer.html"] = { request, _ in
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let land = Land(address: address)
            
            let value = self.gameEngine.realEstateAgent.evaluatePrice(land) ?? 0.0
            let transactionCosts = TransactionCosts(propertyValue: value)
            let raw = Resource.getAppResource(relativePath: "templates/saleOffer.html")
            let template = Template(raw: raw)
            var data = [String:String]()
            data["value"] = transactionCosts.propertyValue.money
            data["tax"] = transactionCosts.tax.money
            data["transactionCosts"] = transactionCosts.fee.money
            data["total"] = transactionCosts.total.money
            data["buyScript"] = JSCode.runScripts(windowIndex, paths: ["/buyProperty.js?\(address.asQueryParams)"]).js
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
        
        server.GET["/buyProperty.js"] = {request, _ in
            let code = JSResponse()
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    code.add(.closeWindow(windowIndex))
                    code.add(.showError(txt: "Invalid request! Missing session ID.", duration: 10))
                    return code.response
            }
            do {
                try self.gameEngine.realEstateAgent.buyProperty(address: address, session: session)
            } catch BuyPropertyError.propertyNotForSale {
                code.add(.closeWindow(windowIndex))
                code.add(.showError(txt: "This property is not for sale any more.", duration: 10))
                return code.response
            } catch BuyPropertyError.problemWithPrice {
                return JSCode.showError(txt: "Internal problem with price evaluation...", duration: 10).response
            } catch BuyPropertyError.notEnoughMoneyInWallet {
                return JSCode.showError(txt: "You don't have enough money to buy this property", duration: 10).response
            } catch {
                return JSCode.showError(txt: "Unexpected error [\(request.address ?? "")]", duration: 10).response
            }
            code.add(.closeWindow(windowIndex))
            return code.response
        }
        
        
        server.GET["/sampleLib.js"] = { _, _ in
            let code = JSResponse()
            code.add(.any("function runIt(){ \(JSCode.showInfo(txt: "runIt", duration: 2).js) }"))
            return code.response
        }
        
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
