//
//  LandRestAPI.swift
//  
//
//  Created by Tomasz Kucharski on 22/10/2021.
//

import Foundation

class LandRestAPI: RestAPI {
    
    override func setupEndpoints() {
        
        
        // MARK: openLandManager.js
        server.GET["/openLandManager.js"] = { request, _ in
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
            
            js.add(.resizeWindow(windowIndex, width: 0.7, height: 0.8))
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
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManager.html"))
            var data = [String:String]()
            
            let propertyHasAccountant = land.accountantID != nil
            
            let incomeForTaxCalculation = 0.0//propertyHasAccountant ? max(0, property.monthlyIncome - property.monthlyMaintenanceCost) : property.monthlyIncome

            if propertyHasAccountant {
                template.assign(variables: ["monthlyIncomeAmortizated":incomeForTaxCalculation.money], inNest: "amortization")
            }
            let incomeTax = incomeForTaxCalculation * self.gameEngine.taxRates.incomeTax
            data["name"] = land.name
            data["type"] = land.type
            data["monthlyIncome"] = ""//property.monthlyIncome.money
            data["taxRate"] = (self.gameEngine.taxRates.incomeTax*100).string
            data["monthlyIncomeTax"] = ""//incomeTax.money
            data["monthlyCosts"] = ""//property.monthlyMaintenanceCost.money
            data["balance"] = ""//(property.monthlyIncome - property.monthlyMaintenanceCost - incomeTax).money
            data["purchasePrice"] = land.purchaseNetValue.money
            data["investmentsValue"] = land.investmentsNetValue.money
            let estimatedValue = 0.0//self.gameEngine.realEstateAgent.estimateValue(property.address)
            data["estimatedValue"] = estimatedValue.money

            data["tileUrl"] = TileType.soldLand.image.path
            template.assign(variables: ["actions": self.landPropertyActions(land: land, windowIndex: windowIndex)])
            
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
    }
    
    
    private func landPropertyActions(land: Land, windowIndex: String) -> String {

        let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManagerLand.html"))
        
        if self.gameEngine.gameMapManager.map.hasDirectAccessToRoad(address: land.address) {

            var buildRoadData = [String:String]()
            let roadOffer = self.gameEngine.constructionServices.roadOffer(landName: land.name)
            
            buildRoadData["name"] = "Road"
            buildRoadData["investmentCost"] = roadOffer.invoice.netValue.money
            buildRoadData["investmentTax"] = roadOffer.invoice.tax.money
            buildRoadData["investmentTotal"] = roadOffer.invoice.total.money
            buildRoadData["investmentDuration"] = "\(roadOffer.duration) months"
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
                buildHouseData["investmentDuration"] = "\(offer.duration) months"
                buildHouseData["actionJS"] = JSCode.runScripts(windowIndex, paths: ["/startInvestment.js?type=apartment&\(land.address.asQueryParams)&storey=\(storey)"]).js
                buildHouseData["actionTitle"] = "Start investment"
                template.assign(variables: buildHouseData, inNest: "investment")
            }
            
        } else {
            let info = "This property has no access to the public road, so the investment options are very narrow."
            template.assign(variables: ["text": info], inNest: "info")
        }
        return template.output()
    }
}
