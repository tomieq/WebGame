//
//  RealEstateAgentRestAPI.swift
//
//
//  Created by Tomasz Kucharski on 22/10/2021.
//

import Foundation

class PropertySalesAPI: RestAPI {
    override func setupEndpoints() {
        // MARK: openSaleOffer
        server.GET[.openSaleOffer] = { request, _ in
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
            var data = [String: String]()

            if offer.property.ownerUUID == SystemPlayer.government.uuid {
                data["sellerName"] = "Government"
                template.assign(variables: ["value": offer.saleInvoice.netValue.money], inNest: "govermentOffer")
            } else {
                if let seller: Player = self.gameEngine.dataStore.find(uuid: offer.property.ownerUUID) {
                    data["sellerName"] = seller.login
                    template.assign(variables: ["value": offer.saleInvoice.netValue.money, "name": seller.login], inNest: "privateOffer")
                }
            }
            let netValue = offer.saleInvoice.netValue
            data["value"] = netValue.money
            data["tax"] = offer.saleInvoice.tax.money
            data["taxRate"] = (offer.saleInvoice.taxRate * 100).rounded(toPlaces: 1).string
            data["transactionFee"] = offer.commissionInvoice.total.money
            data["total"] = (offer.saleInvoice.total + offer.commissionInvoice.total).money
            data["buyScript"] = JSCode.runScripts(windowIndex, paths: ["/buyProperty.js?\(address.asQueryParams)&netValue=\(netValue)"]).js
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }

        // MARK: buyProperty.js
        server.GET["/buyProperty.js"] = { request, _ in
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
            var netValue: Double?
            if let netValueString = request.queryParam("netValue") {
                netValue = Double(netValueString)
            }
            do {
                try self.gameEngine.realEstateAgent.buyProperty(address: address, buyerUUID: session.playerUUID, netPrice: netValue)
            } catch BuyPropertyError.propertyNotForSale {
                code.add(.closeWindow(windowIndex))
                code.add(.showError(txt: "This property is not for sale any more.", duration: 10))
                return code.response
            } catch BuyPropertyError.saleOfferHasChanged {
                code.add(.showWarning(txt: "Sale offer has changed!", duration: 10))
                code.add(.loadHtml(windowIndex, htmlPath: "saleOffer.html?\(address.asQueryParams)"))
                return code.response
            } catch BuyPropertyError.financialTransactionProblem(let reason) {
                return JSCode.showError(txt: reason.description, duration: 10).response
            } catch {
                return JSCode.showError(txt: "Unexpected error [\(request.address ?? "")]", duration: 10).response
            }
            code.add(.closeWindow(windowIndex))
            return code.response
        }

        // MARK: loadNewSaleOfferForm
        server.GET[.loadNewSaleOfferForm] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.loadHtmlInline(windowIndex, htmlPath: "/newSaleOfferForm.html".append(address), targetID: PropertyManagerTopView.domID(windowIndex)))
            return js.response
        }

        // MARK: newSaleOfferForm.html
        server.GET["newSaleOfferForm.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }

            guard let playerSessionID = request.queryParam("playerSessionID"),
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return self.htmlError("Invalid request! Missing sessionID.")
            }
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return self.htmlError("Property not found!")
            }
            guard property.ownerUUID == session.playerUUID else {
                return self.htmlError("You can sell only your own property!")
            }

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertySales/newSaleOfferForm.html"))
            var data = [String: String]()
            data["name"] = property.name
            data["type"] = property.type
            data["price"] = property.purchaseNetValue.moneyFormat
            data["windowIndex"] = windowIndex
            data["submitUrl"] = "/publishSaleOffer.js".append(address)
            data["evaluationJS"] = JSCode.loadHtmlInline(windowIndex, htmlPath: "/propertyValuation.html".append(address), targetID: "valuationContent").js
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }

        // MARK: publishSaleOffer.js
        server.GET["/publishSaleOffer.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            guard let priceString = request.queryParam("price"), let price = Double(priceString) else {
                return self.jsError("Invalid request! Missing price.")
            }
            let js = JSResponse()

            do {
                try self.gameEngine.realEstateAgent.registerSaleOffer(address: address, netValue: price)
                js.add(.showSuccess(txt: "Sale offer published successfully", duration: 5))
                js.add(.loadHtmlInline(windowIndex, htmlPath: RestEndpoint.propertySellStatus.append(address), targetID: PropertyManagerTopView.domID(windowIndex)))
            } catch {
                return self.jsError("Problem with adding sale offer")
            }
            return js.response
        }

        // MARK: loadEditSaleOfferForm
        server.GET[.loadEditSaleOfferForm] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.loadHtmlInline(windowIndex, htmlPath: "/editSaleOffer.html".append(address), targetID: PropertyManagerTopView.domID(windowIndex)))
            return js.response
        }

        // MARK: editSaleOffer.html
        server.GET["/editSaleOffer.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }

            guard let playerSessionID = request.queryParam("playerSessionID"),
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return self.htmlError("Invalid request! Missing sessionID.")
            }
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return self.htmlError("Property not found!")
            }
            guard property.ownerUUID == session.playerUUID else {
                return self.htmlError("You can sell only your own property!")
            }
            guard let offer = self.gameEngine.realEstateAgent.saleOffer(address: address, buyerUUID: "nobody") else {
                return self.htmlError("The offer is not valid any more. Possibly somebody has just bought your property.")
            }

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertySales/editSaleOfferForm.html"))
            var data = [String: String]()
            data["name"] = property.name
            data["type"] = property.type
            data["price"] = offer.saleInvoice.netValue.moneyFormat
            data["money"] = offer.saleInvoice.netValue.money
            data["windowIndex"] = windowIndex
            data["tileUrl"] = self.gameEngine.gameMap.getTile(address: address)?.type.image.path ?? ""
            data["submitUrl"] = "/saveSaleOffer.js".append(address)
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }

        // MARK: saveSaleOffer.js
        server.GET["/saveSaleOffer.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }

            guard let priceString = request.queryParam("price"), let price = Double(priceString) else {
                return self.jsError("Invalid request! Missing price.")
            }
            let js = JSResponse()
            do {
                try self.gameEngine.realEstateAgent.updateSaleOffer(address: address, netValue: price)
            } catch UpdateOfferError.offerDoesNotExist {
                return JSCode.showWarning(txt: "Looks like your offer is not valid any more. Probably someone has just bought your property", duration: 10).response
            } catch {
                return self.jsError("Unknown error \(error)")
            }
            js.add(.showSuccess(txt: "Sale offer updated successfully", duration: 5))
            js.add(.loadHtmlInline(windowIndex, htmlPath: RestEndpoint.propertySellStatus.append(address), targetID: PropertyManagerTopView.domID(windowIndex)))
            return js.response
        }

        // MARK: cancelSaleOffer
        server.GET[.cancelSaleOffer] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            self.gameEngine.realEstateAgent.cancelSaleOffer(address: address)
            js.add(.showSuccess(txt: "Sale offer cancelled successfully", duration: 5))
            js.add(.loadHtmlInline(windowIndex, htmlPath: RestEndpoint.propertySellStatus.append(address), targetID: PropertyManagerTopView.domID(windowIndex)))
            return js.response
        }

        // MARK: propertySellStatus
        server.GET[.propertySellStatus] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.queryParam("playerSessionID"),
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return self.htmlError("Invalid request! Missing session ID.")
            }
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return self.htmlError("Property at \(address.readable) not found!")
            }
            let ownerID = property.ownerUUID
            guard session.playerUUID == ownerID else {
                return self.htmlError("Property at \(address.readable) is not yours!")
            }
            let sellView = PropertySaleStatusView(property: property)
            sellView.setOffer(self.gameEngine.realEstateAgent.saleOffer(address: address, buyerUUID: "random"))
            return sellView.output(windowIndex: windowIndex).asResponse
        }

        // MARK: newSaleOfferForm.html
        server.GET["/propertyValuation.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }

            guard let playerSessionID = request.queryParam("playerSessionID"),
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return self.htmlError("Invalid request! Missing sessionID.")
            }
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return self.htmlError("Property not found!")
            }
            guard property.ownerUUID == session.playerUUID else {
                return self.htmlError("You can valuate only your own property!")
            }
            // TODO: take money from user
            guard let value = self.gameEngine.propertyValuer.estimateValue(address) else {
                return self.htmlError("Problem with property valuation")
            }
            let instantSellValue = value * self.gameEngine.investorAI.params.instantPurchaseToEstimatedValueFactor

            let html = "The estimated value is <b>\(value.money)</b>. If you want to sell the property immediately, set the price under \(instantSellValue.money)."
            return html.asResponse
        }
    }
}
