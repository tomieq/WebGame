//
//  RealEstateAgentRestAPI.swift
//  
//
//  Created by Tomasz Kucharski on 22/10/2021.
//

import Foundation

class RealEstateAgentRestAPI: RestAPI {
    override func setupEndpoints() {

        // MARK: openSaleOffer.js
        server.GET["/openSaleOffer.js"] = { request, _ in
            request.disableKeepAlive = true
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
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }
        
        // MARK: saleOffer.html
        server.GET["/saleOffer.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return .badRequest(.html("Invalid request! Missing window context."))
            }
            guard let address = request.mapPoint else {
                return .badRequest(.html("Invalid request! Missing address."))
            }
            
            guard let playerSessionID = request.queryParam("playerSessionID"),
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                      return .badRequest(.html("Invalid request! Missing sessionID."))
            }
            guard let offer = self.gameEngine.realEstateAgent.saleOffer(address: address, buyerUUID: session.playerUUID) else {
                return .badRequest(.html("Sale offer not found!"))
            }

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/saleOffer.html"))
            var data = [String:String]()
            
            if offer.property.ownerUUID == SystemPlayer.government.uuid {
                data["sellerName"] = "Government"
                template.assign(variables: ["value": offer.saleInvoice.netValue.money], inNest: "govermentOffer")
            } else {
                if let seller: Player = self.gameEngine.dataStore.find(uuid: offer.property.ownerUUID) {
                    data["sellerName"] = seller.login
                    template.assign(variables: ["value": offer.saleInvoice.netValue.money, "name": seller.login], inNest: "privateOffer")
                }
            }
            data["value"] = offer.saleInvoice.netValue.money
            data["tax"] = offer.saleInvoice.tax.money
            data["taxRate"] = (offer.saleInvoice.taxRate * 100).rounded(toPlaces: 1).string
            data["transactionFee"] = offer.commissionInvoice.total.money
            data["total"] = (offer.saleInvoice.total + offer.commissionInvoice.total).money
            data["buyScript"] = JSCode.runScripts(windowIndex, paths: ["/buyProperty.js?\(address.asQueryParams)"]).js
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
        
        // MARK: buyProperty.js
        server.GET["/buyProperty.js"] = {request, _ in
            request.disableKeepAlive = true
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
                try self.gameEngine.realEstateAgent.buyProperty(address: address, buyerUUID: session.playerUUID)
            } catch BuyPropertyError.propertyNotForSale {
                code.add(.closeWindow(windowIndex))
                code.add(.showError(txt: "This property is not for sale any more.", duration: 10))
                return code.response
            } catch BuyPropertyError.financialTransactionProblem(let reason) {
                return JSCode.showError(txt: reason.description, duration: 10).response
            } catch {
                return JSCode.showError(txt: "Unexpected error [\(request.address ?? "")]", duration: 10).response
            }
            code.add(.closeWindow(windowIndex))
            return code.response
        }
        
        // MARK: openPublishSaleOffer.js
        server.GET["/openPublishSaleOffer.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/publishSaleOffer.html?\(address.asQueryParams)"))
            js.add(.disableWindowResizing(windowIndex))
            js.add(.setWindowTitle(windowIndex, title: "Put property on sale"))
            js.add(.resizeWindow(windowIndex, width: 600, height: 300))
            js.add(.positionWindow(windowIndex, address))
            return js.response
        }

        // MARK: publishSaleOffer.html
        server.GET["/publishSaleOffer.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return .badRequest(.html("Invalid request! Missing window context."))
            }
            guard let address = request.mapPoint else {
                return .badRequest(.html("Invalid request! Missing address."))
            }
            
            guard let playerSessionID = request.queryParam("playerSessionID"),
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                      return .badRequest(.html("Invalid request! Missing sessionID."))
            }
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return .badRequest(.html("Property not found!"))
            }
            guard property.ownerUUID == session.playerUUID else {
                return .badRequest(.html("You can sell only your own property!"))
            }

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/publishSaleOffer.html"))
            var data = [String:String]()
            data["name"] = property.name
            data["type"] = property.type
            data["price"] = property.purchaseNetValue.string
            data["windowIndex"] = windowIndex
            data["tileUrl"] = self.gameEngine.gameMap.getTile(address: address)?.type.image.path ?? ""
            data["submitUrl"] = "/publishSaleOffer.js?\(address.asQueryParams)"
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
        
        // MARK: openPublishSaleOffer.js
        server.GET["/publishSaleOffer.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            guard let priceString = request.queryParam("price"), let price = Double(priceString) else {
                return JSCode.showError(txt: "Invalid request! Missing price.", duration: 10).response
            }
            let js = JSResponse()
            
            do {
                try self.gameEngine.realEstateAgent.registerSaleOffer(address: address, netValue: price)
                js.add(.showSuccess(txt: "Sale offer published successfully", duration: 5))
                js.add(.closeWindow(windowIndex))
            } catch {
                return JSCode.showError(txt: "Problem with adding sale offer", duration: 10).response
            }
            
            return js.response
        }
    }
}