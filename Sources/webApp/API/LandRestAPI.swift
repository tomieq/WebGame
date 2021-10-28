//
//  LandRestAPI.swift
//  
//
//  Created by Tomasz Kucharski on 22/10/2021.
//

import Foundation

class LandRestAPI: RestAPI {
    
    override func setupEndpoints() {
        
        
        // MARK: openLandManager
        server.GET[.openLandManager] = { request, _ in
            request.disableKeepAlive = true
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.openWindow(name: "Land Manager", path: "/initLandManager.js?\(address.asQueryParams)", width: 0.7, height: 0.8, singletonID: address.asQueryParams))
            return js.response
        }
        
        // MARK: initLandManager.js
        server.GET["initLandManager.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.setWindowTitle(windowIndex, title: "Land management"))
            js.add(.loadHtml(windowIndex, htmlPath: "/landManager.html?\(address.asQueryParams)"))
            
            js.add(.disableWindowResizing(windowIndex))
            js.add(.centerWindow(windowIndex))
            return js.response
        }

        // MARK: landManager.html
        server.GET["/landManager.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    return .ok(.text("Invalid request! Missing session ID."))
            }
            guard let windowIndex = request.queryParam("windowIndex") else {
                return .ok(.text("Invalid request! Missing window context."))
            }
            guard let address = request.mapPoint else {
                return .ok(.text("Invalid request! Missing address."))
            }
            guard let land: Land = self.dataStore.find(address: address) else {
                return .ok(.text("Property at \(address.description) not found!"))
            }
            let ownerID = land.ownerUUID
            guard session.playerUUID == ownerID else {
                return .ok(.text("Property at \(address.description) is not yours!"))
            }
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/landManager.html"))
            var data = [String:String]()
            
            if let offer = self.gameEngine.realEstateAgent.saleOffer(address: address, buyerUUID: "check") {
                var data = [String:String]()
                data["price"] = offer.saleInvoice.netValue.money
                data["cancelOfferJS"] = JSCode.runScripts(windowIndex, paths: [RestEndpoint.cancelSaleOffer.append(address)]).js
                data["editOfferJS"] = JSCode.runScripts(windowIndex, paths: [RestEndpoint.openEditSaleOffer.append(address)]).js
                template.assign(variables: data, inNest: "forSale")
            } else {
                var data = [String:String]()
                data["publishOfferJS"] = JSCode.runScripts(windowIndex, paths: ["/openPublishSaleOffer.js?\(address.asQueryParams)"]).js
                template.assign(variables: data, inNest: "notForSale")
            }
            
            data["name"] = land.name
            data["type"] = land.type
            data["purchasePrice"] = land.purchaseNetValue.rounded(toPlaces: 0).money
            data["investmentsValue"] = land.investmentsNetValue.money
            
            let monthlyCosts = self.gameEngine.propertyBalanceCalculator.getMontlyCosts(address: address)
            for cost in monthlyCosts {
                var data: [String:String] = [:]
                data["name"] = cost.title
                data["netValue"] = cost.netValue.money
                data["taxRate"] = (cost.taxRate * 100).rounded(toPlaces: 0).string
                data["taxValue"] = cost.tax.money
                data["total"] = cost.total.money
                template.assign(variables: data, inNest: "cost")
            }
            let totalCosts = monthlyCosts.map{$0.total}.reduce(0, +)
            var costData: [String:String] = [:]
            costData["netValue"] = monthlyCosts.map{$0.netValue}.reduce(0, +).money
            costData["taxValue"] = monthlyCosts.map{$0.tax}.reduce(0, +).money
            costData["total"] = totalCosts.money
            template.assign(variables: costData, inNest: "costTotal")
            
            let monthlyIncome = self.gameEngine.propertyBalanceCalculator.getMonthlyIncome(address: address)

            for income in monthlyIncome {
                var data: [String:String] = [:]
                data["name"] = income.name
                data["netValue"] = income.netValue.money
                template.assign(variables: data, inNest: "income")
            }
            let balance = (-1 * totalCosts) + monthlyIncome.map{$0.netValue}.reduce(0, +)
            var incomeData: [String:String] = [:]
            incomeData["name"] = "Costs"
            incomeData["netValue"] = (-1 * totalCosts).money
            template.assign(variables: incomeData, inNest: "income")
            incomeData = [:]
            incomeData["netValue"] = balance.money
            template.assign(variables: incomeData, inNest: "incomeTotal")
            
            data["monthlyIncome"] = ""//property.monthlyIncome.money
            data["taxRate"] = (self.gameEngine.taxRates.incomeTax*100).string
            data["monthlyIncomeTax"] = ""//incomeTax.money
            data["monthlyCosts"] = ""//property.monthlyMaintenanceCost.money
            data["balance"] = ""//(property.monthlyIncome - property.monthlyMaintenanceCost - incomeTax).money
            
            let estimatedValue = 0.0//self.gameEngine.realEstateAgent.estimateValue(property.address)
            data["estimatedValue"] = estimatedValue.money

            data["tileUrl"] = TileType.soldLand.image.path
            
            self.landPropertyActions(template: template, land: land, windowIndex: windowIndex)
            
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
    }
    
    
    private func landPropertyActions(template: Template, land: Land, windowIndex: String) {
        
        if self.gameEngine.gameMapManager.map.hasDirectAccessToRoad(address: land.address) {

            var buildRoadData = [String:String]()
            let roadOffer = self.gameEngine.constructionServices.roadOffer(landName: land.name)
            
            buildRoadData["name"] = "Road"
            buildRoadData["investmentCost"] = roadOffer.invoice.netValue.money
            buildRoadData["investmentTax"] = roadOffer.invoice.tax.money
            buildRoadData["investmentTotal"] = roadOffer.invoice.total.money
            buildRoadData["investmentDuration"] = "\(roadOffer.duration) months"
            buildRoadData["taxRate"] = (roadOffer.invoice.taxRate * 100).rounded(toPlaces: 0).string
            buildRoadData["actionJS"] = JSCode.runScripts(windowIndex, paths: ["/startInvestment.js?type=road&\(land.address.asQueryParams)"]).js
            buildRoadData["actionTitle"] = "Start investment"
            template.assign(variables: buildRoadData, inNest: "investment")
            
            for storey in [4, 6, 8, 10] {
                var buildHouseData = [String:String]()
                
                let offer = self.gameEngine.constructionServices.residentialBuildingOffer(landName: land.name, storeyAmount: storey)

                buildHouseData["name"] = "\(storey) storey Apartment"
                buildHouseData["investmentCost"] = offer.invoice.netValue.money
                buildHouseData["investmentCost"] = offer.invoice.netValue.money
                buildHouseData["investmentTax"] = offer.invoice.tax.money
                buildHouseData["investmentTotal"] = offer.invoice.total.money
                buildHouseData["taxRate"] = (offer.invoice.taxRate * 100).rounded(toPlaces: 0).string
                buildHouseData["investmentDuration"] = "\(offer.duration) months"
                buildHouseData["actionJS"] = JSCode.runScripts(windowIndex, paths: ["/startInvestment.js?type=apartment&\(land.address.asQueryParams)&storey=\(storey)"]).js
                buildHouseData["actionTitle"] = "Start investment"
                template.assign(variables: buildHouseData, inNest: "investment")
            }
            
        } else {
            let info = "This property has no access to the public road, so the investment options are very narrow."
            template.assign(variables: ["text": info], inNest: "info")
        }
    }
}
