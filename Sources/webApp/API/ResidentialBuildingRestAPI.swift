//
//  ResidentialBuildingRestAPI.swift
//  
//
//  Created by Tomasz Kucharski on 26/10/2021.
//

import Foundation


class ResidentialBuildingRestAPI: RestAPI {
    
    override func setupEndpoints() {
        
        // MARK: openBuildingManager
        server.GET[.openBuildingManager] = { request, _ in
            request.disableKeepAlive = true
  
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.openWindow(name: "Residential Building", path: "/initBuildingManager.js".append(address), width: 0.7, height: 0.8, singletonID: address.asQueryParams))
            return js.response
        }
        
        // MARK: initBuildingManager.js
        server.GET["/initBuildingManager.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/buildingManager.html?\(address.asQueryParams)"))
            js.add(.disableWindowResizing(windowIndex))
            js.add(.centerWindow(windowIndex))
            return js.response
        }

        // MARK: buildingManager.html
        server.GET["/buildingManager.html"] = { request, _ in
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
            guard let building: ResidentialBuilding = self.dataStore.find(address: address) else {
                return self.htmlError("Property at \(address.description) not found!")
            }
            let ownerID = building.ownerUUID
            guard session.playerUUID == ownerID else {
                return self.htmlError("Property at \(address.description) is not yours!")
            }
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/buildingManager.html"))
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
            
            let monthlyCosts = self.gameEngine.propertyBalanceCalculator.getMontlyCosts(address: address)
            
            data["name"] = building.name
            data["type"] = building.type
            data["purchasePrice"] = building.purchaseNetValue.rounded(toPlaces: 0).money
            data["investmentsValue"] = building.investmentsNetValue.money
            
            for cost in monthlyCosts {
                var data: [String:String] = [:]
                data["name"] = cost.title
                data["netValue"] = cost.netValue.money
                data["taxRate"] = (cost.taxRate * 100).rounded(toPlaces: 0).string
                data["taxValue"] = cost.tax.money
                data["total"] = cost.total.money
                template.assign(variables: data, inNest: "cost")
            }
            if monthlyCosts.count > 0 {
                var data: [String:String] = [:]
                data["netValue"] = monthlyCosts.map{$0.netValue}.reduce(0, +).money
                data["taxValue"] = monthlyCosts.map{$0.tax}.reduce(0, +).money
                data["total"] = monthlyCosts.map{$0.total}.reduce(0, +).money
                template.assign(variables: data, inNest: "costTotal")
            }
            data["monthlyIncome"] = ""//property.monthlyIncome.money
            data["taxRate"] = (self.gameEngine.taxRates.incomeTax*100).string
            data["monthlyIncomeTax"] = ""//incomeTax.money
            data["monthlyCosts"] = ""//property.monthlyMaintenanceCost.money
            data["balance"] = ""//(property.monthlyIncome - property.monthlyMaintenanceCost - incomeTax).money
            
            let estimatedValue = 0.0//self.gameEngine.realEstateAgent.estimateValue(property.address)
            data["estimatedValue"] = estimatedValue.money

            if building.isUnderConstruction {
                data["tileUrl"] = TileType.buildingUnderConstruction(size: building.storeyAmount).image.path
            } else {
                data["tileUrl"] = TileType.building(size: building.storeyAmount).image.path
            }
            
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
    }
}
