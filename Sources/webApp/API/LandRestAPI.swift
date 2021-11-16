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
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.openWindow(name: "Land Manager", path: "/initLandManager.js".append(address), width: 680, height: 500, singletonID: address.asQueryParams))
            return js.response
        }
        
        // MARK: initLandManager.js
        server.GET["initLandManager.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/landManager.html".append(address)))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }

        // MARK: landManager.html
        server.GET["/landManager.html"] = { request, _ in
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
            guard let land: Land = self.dataStore.find(address: address) else {
                return self.htmlError("Property at \(address.readable) not found!")
            }
            let ownerID = land.ownerUUID
            guard session.playerUUID == ownerID else {
                return self.htmlError("Property at \(address.readable) is not yours!")
            }
            
            let view = PropertyManagerTopView(windowIndex: windowIndex)
            let domID = PropertyManagerTopView.domID(windowIndex)
            view.addTab("Wallet balance", onclick: .loadHtmlInline(windowIndex, htmlPath: RestEndpoint.propertyWalletBalance.append(address), targetID: domID))
            view.addTab("Sell options", onclick: .loadHtmlInline(windowIndex, htmlPath: RestEndpoint.propertySellStatus.append(address), targetID: domID))
            view.addTab("Investments", onclick: .loadHtmlInline(windowIndex, htmlPath: "landInvestments.html".append(address), targetID: domID))
            
            view.setPropertyType(land.type)
                .setTileImage(TileType.soldLand.image.path)
            
            view.addTip("Own piece of land is a great start for making investments.")
            
            let balanceView = PropertyBalanceView()
            balanceView.setMonthlyCosts(self.gameEngine.propertyBalanceCalculator.getMontlyCosts(address: address))
            balanceView.setMonthlyIncome(self.gameEngine.propertyBalanceCalculator.getMonthlyIncome(address: address))
            balanceView.setProperty(land)

            view.setInitialContent(html: balanceView.output())
            return view.output().asResponse
        }
        
        // MARK: landBalance.html
        server.GET["/landInvestments.html"] = { request, _ in
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
            guard let land: Land = self.dataStore.find(address: address) else {
                return self.htmlError("Property at \(address.readable) not found!")
            }
            let ownerID = land.ownerUUID
            guard session.playerUUID == ownerID else {
                return self.htmlError("Property at \(address.readable) is not yours!")
            }
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/landManager.html"))

            self.landPropertyActions(template: template, land: land, windowIndex: windowIndex)
            return template.asResponse()
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
            buildRoadData["actionJS"] = JSCode.runScripts(windowIndex, paths: [RestEndpoint.startInvestment.append(land.address).appending("&type=road")]).js
            buildRoadData["actionTitle"] = "Start investment"
            template.assign(variables: buildRoadData, inNest: "investment")
            
            var buildParkingData = [String:String]()
            let parkingOffer = self.gameEngine.constructionServices.parkingOffer(landName: land.name)
            
            buildParkingData["name"] = "Parking lot"
            buildParkingData["investmentCost"] = parkingOffer.invoice.netValue.money
            buildParkingData["investmentTax"] = parkingOffer.invoice.tax.money
            buildParkingData["investmentTotal"] = parkingOffer.invoice.total.money
            buildParkingData["investmentDuration"] = "\(parkingOffer.duration) months"
            buildParkingData["taxRate"] = (parkingOffer.invoice.taxRate * 100).rounded(toPlaces: 0).string
            buildParkingData["actionJS"] = JSCode.runScripts(windowIndex, paths: [RestEndpoint.startInvestment.append(land.address).appending("&type=parking")]).js
            buildParkingData["actionTitle"] = "Start investment"
            template.assign(variables: buildParkingData, inNest: "investment")
            
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
