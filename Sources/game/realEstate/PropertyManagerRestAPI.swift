//
//  PropertyManagerRestAPI.swift
//  
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation
import Swifter

class PropertyManagerRestAPI {
    
    let gameEngine: GameEngine
    
    init(_ server: HttpServer, gameEngine: GameEngine) {
        
        self.gameEngine = gameEngine
        
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
            
            let value = self.gameEngine.realEstateAgent.estimatePrice(land)
            let transactionCosts = Invoice(netValue: value, taxPercent: TaxRates.propertyPurchaseTax, feePercent: 1)
            let raw = Resource.getAppResource(relativePath: "templates/saleOffer.html")
            let template = Template(raw: raw)
            var data = [String:String]()
            data["value"] = transactionCosts.netValue.money
            data["tax"] = transactionCosts.tax.money
            data["taxRate"] = Int(transactionCosts.taxPercent).string
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
            } catch BuyPropertyError.financialTransactionProblem(let reason) {
                return JSCode.showError(txt: reason, duration: 10).response
            } catch {
                return JSCode.showError(txt: "Unexpected error [\(request.address ?? "")]", duration: 10).response
            }
            code.add(.closeWindow(windowIndex))
            return code.response
        }
        
        server.GET["/openPropertyInfo.js"] = { request, _ in
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/propertyInfo.html?\(address.asQueryParams)"))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }
        
        server.GET["/propertyInfo.html"] = { request, _ in
            guard let _ = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return .ok(.text("Property at \(address.description) not found!"))
            }
            guard let ownerID = property.ownerID else {
                return .ok(.text("Property at \(address.description) has no owner!"))
            }
            let owner = Storage.shared.getPlayer(id: ownerID)
            
            let raw = Resource.getAppResource(relativePath: "templates/propertyInfo.html")
            let template = Template(raw: raw)
            var data = [String:String]()
            data["type"] = property.type
            data["name"] = property.name
            data["owner"] = owner?.login ?? "nil"
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
        
        server.GET["/openPropertyManager.js"] = { request, _ in
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.setWindowTitle(windowIndex, title: "Property management"))
            js.add(.loadHtml(windowIndex, htmlPath: "/propertyManager.html?\(address.asQueryParams)"))
            js.add(.resizeWindow(windowIndex, width: 0.7, height: 0.8))
            js.add(.disableWindowResizing(windowIndex))
            js.add(.centerWindow(windowIndex))
            return js.response
        }
        
        server.GET["/propertyManager.html"] = { request, _ in
            
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
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return .ok(.text("Property at \(address.description) not found!"))
            }
            guard let ownerID = property.ownerID, session.player.id == ownerID else {
                return .ok(.text("Property at \(address.description) is not yours!"))
            }
            
            let raw = Resource.getAppResource(relativePath: "templates/propertyManager.html")
            let template = Template(raw: raw)
            var data = [String:String]()
            data["name"] = property.name
            data["type"] = property.type
            data["monthlyIncome"] = property.monthlyIncome.money
            data["monthlyCosts"] = property.monthlyMaintenanceCost.money
            data["balance"] = (property.monthlyIncome - property.monthlyMaintenanceCost).money
            data["purchasePrice"] = property.purchaseNetValue?.money ?? ""
            data["investmentsValue"] = property.investmentsNetValue.money
            let estimatedValue = self.gameEngine.realEstateAgent.estimatePrice(property)
            data["estimatedValue"] = estimatedValue.money
            data["instantSellJS"] = JSCode.runScripts(windowIndex, paths: ["/instantSell.js?\(address.asQueryParams)&propertyID=\(property.id)"]).js
            data["instantSellPrice"] = (estimatedValue * PriceList.instantSellFraction).money
            

            if let land = property as? Land {
                data["tileUrl"] = TileType.soldLand.image.path
                template.assign(variables: ["actions": self.landPropertyActions(land: land, windowIndex: windowIndex)])
            } else if property is Road {
                data["tileUrl"] = TileType.street(type: .local(.localY)).image.path

                let info = "Roads do not make any income, but they increase market value of surrounding area. Notice that there are the maintenance costs there, so the best approach is to sell the road. Road cannot be destroyed by government or any other players."
                template.assign(variables: ["text":info], inNest: "info")
            } else if let apartment = property as? ResidentialBuilding {
                data["tileUrl"] = TileType.building(size: apartment.storeyAmount).image.path
                template.assign(variables: ["actions": self.buildingActions(building: apartment, windowIndex: windowIndex, session: session)])
           }
            
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
        
        server.GET["/startInvestment.js"] = { request, _ in
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
            guard let investmentType = request.queryParam("type") else {
                return JSCode.showError(txt: "Invalid request! Missing or invalid investmentType.", duration: 10).response
            }
            
            do {
                switch investmentType {
                    case "road":
                        try self.gameEngine.realEstateAgent.buildRoad(address: address, session: session)
                    case "apartment":
                        guard let storeyValue = request.queryParam("storey"), let storeyAmount = Int(storeyValue) else {
                            return JSCode.showError(txt: "Invalid request! Missing storeyAmount.", duration: 10).response
                        }
                        try self.gameEngine.realEstateAgent.buildResidentialBuilding(address: address, session: session, storeyAmount: storeyAmount)
                    default:
                        return JSCode.showError(txt: "Invalid request! Invalid investmentType \(investmentType).", duration: 10).response
                }
                
            } catch StartInvestmentError.financialTransactionProblem(let reason) {
                return JSCode.showError(txt: reason , duration: 10).response
            } catch StartInvestmentError.formalProblem(let reason) {
                return JSCode.showError(txt: reason , duration: 10).response
            } catch {
                return JSCode.showError(txt: "Unexpected error [\(request.address ?? "")]", duration: 10).response
            }
            code.add(.closeWindow(windowIndex))
            return code.response
        }
        
        server.GET["/instantSell.js"] = { request, _ in
        let code = JSResponse()
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return JSCode.showError(txt: "Property at \(address.description) not found!", duration: 10).response
            }
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    code.add(.closeWindow(windowIndex))
                    code.add(.showError(txt: "Invalid request! Missing session ID.", duration: 10))
                    return code.response
            }
            guard property.ownerID == session.player.id else {
                code.add(.showError(txt: "You can sell only your properties.", duration: 10))
                return code.response
            }
            self.gameEngine.realEstateAgent.instantSell(address: address, session: session)
            code.add(.showSuccess(txt: "Successful sell transaction", duration: 5))
            code.add(.closeWindow(windowIndex))
            return code.response
        }
        
        server.GET["/rentApartment.js"] = { request, _ in
        let code = JSResponse()
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            
            guard let propertyID = request.queryParam("propertyID") else {
                return JSCode.showError(txt: "Invalid request! Missing propertyID.", duration: 10).response
            }
            
            guard let apartment = Storage.shared.getApartment(id: propertyID) else {
                return JSCode.showError(txt: "Property \(propertyID) not found!", duration: 10).response
            }
            guard apartment.address == address else {
                return JSCode.showError(txt: "Property address mismatch.", duration: 10).response
            }
            
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    code.add(.closeWindow(windowIndex))
                    code.add(.showError(txt: "Invalid request! Missing session ID.", duration: 10))
                    return code.response
            }
            guard apartment.ownerID == session.player.id else {
                code.add(.showError(txt: "You can rent only your properties.", duration: 10))
                return code.response
            }
            self.gameEngine.realEstateAgent.rentApartment(apartment)
            code.add(.showSuccess(txt: "Successful rental", duration: 5))
            code.add(.loadHtml(windowIndex, htmlPath: "/propertyManager.html?\(apartment.address.asQueryParams)"))
            return code.response
        }
    }
    
    private func landPropertyActions(land: Land, windowIndex: String) -> String {
        let raw = Resource.getAppResource(relativePath: "templates/propertyManagerLand.html")
        let template = Template(raw: raw)
        
        if self.gameEngine.realEstateAgent.hasDirectAccessToRoad(address: land.address) {

            var buildRoadData = [String:String]()
            let investTransaction = Invoice(netValue: InvestmentPrice.buildingRoad(), taxPercent: TaxRates.investmentTax)
            buildRoadData["name"] = "Road"
            buildRoadData["investmentCost"] = investTransaction.netValue.money
            buildRoadData["investmentTax"] = investTransaction.tax.money
            buildRoadData["investmentTotal"] = investTransaction.total.money
            buildRoadData["investmentDuration"] = "3 months"
            buildRoadData["actionJS"] = JSCode.runScripts(windowIndex, paths: ["/startInvestment.js?type=road&\(land.address.asQueryParams)"]).js
            buildRoadData["actionTitle"] = "Start investment"
            template.assign(variables: buildRoadData, inNest: "investment")
            
            [4, 6, 8, 10].forEach { storey in
                var buildHouseData = [String:String]()
                let invoice = Invoice(netValue: InvestmentPrice.buildingApartment(storey: storey), taxPercent: TaxRates.investmentTax)
                buildHouseData["name"] = "\(storey) storey Apartment"
                buildHouseData["investmentCost"] = invoice.netValue.money
                buildHouseData["investmentCost"] = invoice.netValue.money
                buildHouseData["investmentTax"] = invoice.tax.money
                buildHouseData["investmentTotal"] = invoice.total.money
                buildHouseData["investmentDuration"] = "\((9+storey)) months"
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
    
    
    private func buildingActions(building: ResidentialBuilding, windowIndex: String, session: PlayerSession) -> String {
        let raw = Resource.getAppResource(relativePath: "templates/propertyManagerApartment.html")
        let template = Template(raw: raw)
        let myApartments = Storage.shared.getApartments(address: building.address).filter{ $0.ownerID == session.player.id }
        for i in (1...building.storeyAmount) {
            let storey = building.storeyAmount - i + 1
            template.assign(variables: ["storey": storey.string], inNest: "storey")
        }
        myApartments.forEach { apartment in
            var data = [String:String]()
            data["name"] = apartment.name
            data["status"] = apartment.isRented ? "RENTED" : "<i class='fa fa-exclamation-triangle'></i> EMPTY"
            data["monthlyRentalFee"] = apartment.monthlyRentalFee.money
            data["monthlyBills"] = apartment.monthlyBills.money
            data["monthlyBalance"] = (apartment.monthlyRentalFee - apartment.monthlyBills).money
            let estimatedPrice = self.gameEngine.realEstateAgent.estimateApartmentValue(apartment)
            data["estimatedValue"] = estimatedPrice.money
            data["instantSellPrice"] = (estimatedPrice * 0.85).money
            data["instantSellJS"] = JSCode.runScripts(windowIndex, paths: ["/instantApartmentSell.js?\(apartment.address.asQueryParams)&propertyID=\(apartment.id)"]).js
            
            if apartment.isRented {
                data["actionTitle"] = "Kick tenants"
                data["actionJS"] = JSCode.runScripts(windowIndex, paths: ["/kickTenantsFromApartment.js?\(apartment.address.asQueryParams)&propertyID=\(apartment.id)"]).js
            } else {
                
                let estimatedRent = self.gameEngine.realEstateAgent.estimateRentFee(apartment).money
                data["actionTitle"] = "Rent for \(estimatedRent)"
                data["actionJS"] = JSCode.runScripts(windowIndex, paths: ["/rentApartment.js?\(apartment.address.asQueryParams)&propertyID=\(apartment.id)"]).js
            }
            template.assign(variables: data, inNest: "apartment")
        }
        return template.output()
    }
}
