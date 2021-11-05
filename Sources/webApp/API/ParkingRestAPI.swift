//
//  ParkingRestAPI.swift
//  
//
//  Created by Tomasz Kucharski on 04/11/2021.
//

import Foundation

class ParkingRestAPI: RestAPI {
    
    override func setupEndpoints() {
        
        
        // MARK: openParkingManager
        server.GET[.openParkingManager] = { request, _ in
            request.disableKeepAlive = true
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.openWindow(name: "Parking Manager", path: "/initParkingManager.js".append(address), width: 580, height: 470, singletonID: address.asQueryParams))
            var points = self.gameEngine.gameMap.getNeighbourAddresses(to: address, radius: 1)
            points.append(contentsOf: self.gameEngine.gameMap.getNeighbourAddresses(to: address, radius: 2))
            js.add(.highlightPoints(points, color: "green"))
            let competitors = self.gameEngine.propertyBalanceCalculator.getParkingsAroundAddress(address)
            js.add(.highlightPoints(competitors, color: "red"))
            return js.response
        }
        
        // MARK: initParkingManager.js
        server.GET["initParkingManager.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/parkingManager.html".append(address)))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }

        // MARK: parkingManager.html
        server.GET["/parkingManager.html"] = { request, _ in
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
            guard let parking: Parking = self.dataStore.find(address: address) else {
                return self.htmlError("Property at \(address.description) not found!")
            }
            let ownerID = parking.ownerUUID
            guard session.playerUUID == ownerID else {
                return self.htmlError("Property at \(address.description) is not yours!")
            }
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/parkingManager.html"))
            var data = [String:String]()
            
            if let offer = self.gameEngine.realEstateAgent.saleOffer(address: address, buyerUUID: "check") {
                var data = [String:String]()
                data["price"] = offer.saleInvoice.netValue.money
                data["cancelOfferJS"] = JSCode.runScripts(windowIndex, paths: [RestEndpoint.cancelSaleOffer.append(address)]).js
                data["editOfferJS"] = JSCode.runScripts(windowIndex, paths: [RestEndpoint.openEditSaleOffer.append(address)]).js
                template.assign(variables: data, inNest: "forSale")
            } else {
                var data = [String:String]()
                data["publishOfferJS"] = JSCode.runScripts(windowIndex, paths: ["/openPublishSaleOffer.js".append(address)]).js
                template.assign(variables: data, inNest: "notForSale")
            }
            
            data["name"] = parking.name
            data["type"] = parking.type
            data["purchasePrice"] = parking.purchaseNetValue.rounded(toPlaces: 0).money
            data["investmentsValue"] = parking.investmentsNetValue.money
            
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

            data["tileUrl"] = TileType.parking(type: .leftConnection).image.path
            
            
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
    }

}
