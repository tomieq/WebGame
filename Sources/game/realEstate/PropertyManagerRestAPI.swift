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
    private let dataStore: DataStoreProvider
    
    init(_ server: HttpServer, gameEngine: GameEngine) {
        
        self.gameEngine = gameEngine
        self.dataStore = gameEngine.dataStore
        
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
            js.add(.setWindowTitle(windowIndex, title: "Land property"))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }
        
        server.GET["/saleOffer.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return .badRequest(.html("Invalid request! Missing window context."))
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            
            let value = self.gameEngine.realEstateAgent.estimateValue(address)
            let offer = Invoice(title: "Offer", netValue: value, taxRate: self.gameEngine.taxRates.propertyPurchaseTax)
            let transactionFee = offer.netValue * self.gameEngine.realEstateAgent.priceList.realEstateSellPropertyCommisionFee

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/saleOffer.html"))
            var data = [String:String]()
            data["value"] = offer.netValue.money
            data["tax"] = offer.tax.money
            data["taxRate"] = (offer.taxRate * 100).rounded(toPlaces: 1).string
            data["feeRate"] = (self.gameEngine.realEstateAgent.priceList.realEstateSellPropertyCommisionFee * 100).rounded(toPlaces: 1).string
            data["transactionFee"] = transactionFee.money
            data["total"] = (offer.total + transactionFee).money
            data["buyScript"] = JSCode.runScripts(windowIndex, paths: ["/buyLandProperty.js?\(address.asQueryParams)"]).js
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
        
        server.GET["/buyLandProperty.js"] = {request, _ in
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
                try self.gameEngine.realEstateAgent.buyLandProperty(address: address, playerUUID: session.playerUUID)
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
            request.disableKeepAlive = true
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
            request.disableKeepAlive = true
            guard let _ = request.queryParam("windowIndex") else {
                return .badRequest(.html("Invalid request! Missing window context."))
            }
            guard let address = request.mapPoint else {
                return .badRequest(.html("Invalid request! Missing address."))
            }
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return .badRequest(.html("Property at \(address.description) not found!"))
            }
            guard let ownerID = property.ownerID else {
                return .badRequest(.html("Property at \(address.description) has no owner!"))
            }
            let owner = self.dataStore.find(uuid: ownerID)
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyInfo.html"))
            var data = [String:String]()
            data["type"] = property.type
            data["name"] = property.name
            data["owner"] = owner?.login ?? "nil"
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
        
        server.GET["/openPropertyManager.js"] = { request, _ in
            request.disableKeepAlive = true
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
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return .ok(.text("Property at \(address.description) not found!"))
            }
            guard let ownerID = property.ownerID, session.playerUUID == ownerID else {
                return .ok(.text("Property at \(address.description) is not yours!"))
            }
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManager.html"))
            var data = [String:String]()
            
            let propertyHasAccountant = property.accountantID != nil
            let incomeForTaxCalculation = propertyHasAccountant ? max(0, property.monthlyIncome - property.monthlyMaintenanceCost) : property.monthlyIncome

            if propertyHasAccountant {
                template.assign(variables: ["monthlyIncomeAmortizated":incomeForTaxCalculation.money], inNest: "amortization")
            }
            let incomeTax = incomeForTaxCalculation * self.gameEngine.taxRates.incomeTax
            data["name"] = property.name
            data["type"] = property.type
            data["monthlyIncome"] = property.monthlyIncome.money
            data["taxRate"] = (self.gameEngine.taxRates.incomeTax*100).string
            data["monthlyIncomeTax"] = incomeTax.money
            data["monthlyCosts"] = property.monthlyMaintenanceCost.money
            data["balance"] = (property.monthlyIncome - property.monthlyMaintenanceCost - incomeTax).money
            data["purchasePrice"] = property.purchaseNetValue?.money ?? ""
            data["investmentsValue"] = property.investmentsNetValue.money
            let estimatedValue = self.gameEngine.realEstateAgent.estimateValue(property.address)
            data["estimatedValue"] = estimatedValue.money
            if !property.isUnderConstruction {
                var data = [String:String]()
                data["instantSellJS"] = JSCode.runScripts(windowIndex, paths: ["/instantSell.js?\(address.asQueryParams)&propertyID=\(property.id)"]).js
                data["instantSellPrice"] = (estimatedValue * self.gameEngine.realEstateAgent.priceList.instantSellValue).money
                template.assign(variables: data, inNest: "sellOptions")
            }

            if let land = property as? Land {
                data["tileUrl"] = TileType.soldLand.image.path
                template.assign(variables: ["actions": self.landPropertyActions(land: land, windowIndex: windowIndex)])
            } else if property is Road {
                data["tileUrl"] = TileType.street(type: .local(.localY)).image.path

                let info = "Roads do not make any income, but they increase market value of surrounding area. Notice that there are the maintenance costs there, so the best approach is to sell the road. Road cannot be destroyed by government or any other players."
                template.assign(variables: ["text":info], inNest: "info")
            } else if let building = property as? ResidentialBuilding {
                if building.isUnderConstruction {
                    data["tileUrl"] = TileType.buildingUnderConstruction(size: building.storeyAmount).image.path
                } else {
                    data["tileUrl"] = TileType.building(size: building.storeyAmount).image.path
                }
                
                if !building.isUnderConstruction {
                    var costs: [String:String] = [:]
                    costs["title"] = "Montly building maintenance cost"
                    let buildingMaintenanceCost = self.gameEngine.realEstateAgent.priceList.montlyResidentialBuildingCost + self.gameEngine.realEstateAgent.priceList.montlyResidentialBuildingCostPerStorey * building.storeyAmount.double
                    costs["money"] = buildingMaintenanceCost.money
                    template.assign(variables: costs, inNest: "montlyPartialCost")
                    costs = [:]
                    costs["title"] = "Montly flats maintenance cost"
                    costs["money"] = (building.monthlyMaintenanceCost - buildingMaintenanceCost).money
                    template.assign(variables: costs, inNest: "montlyPartialCost")
                }
                template.assign(variables: ["actions": self.buildingActions(building: building, windowIndex: windowIndex, session: session)])
           }
            
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
        
        server.GET["/startInvestment.js"] = { request, _ in
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
            guard let investmentType = request.queryParam("type") else {
                return JSCode.showError(txt: "Invalid request! Missing or invalid investmentType.", duration: 10).response
            }
            
            do {
                switch investmentType {
                    case "road":
                    try self.gameEngine.constructionServices.startRoadInvestment(address: address, playerUUID: session.playerUUID)
                    case "apartment":
                        guard let storeyValue = request.queryParam("storey"), let storeyAmount = Int(storeyValue) else {
                            return JSCode.showError(txt: "Invalid request! Missing storeyAmount.", duration: 10).response
                        }
                        try self.gameEngine.constructionServices.startResidentialBuildingInvestment(address: address, playerUUID: session.playerUUID, storeyAmount: storeyAmount)
                    default:
                        return JSCode.showError(txt: "Invalid request! Invalid investmentType \(investmentType).", duration: 10).response
                }
                
            } catch ConstructionServicesError.addressNotFound {
                return JSCode.showError(txt: "You can build only on an empty land.", duration: 10).response
            } catch ConstructionServicesError.playerIsNotPropertyOwner {
                return JSCode.showError(txt: "You can invest only on your properties.", duration: 10).response
            } catch ConstructionServicesError.noDirectAccessToRoad {
                return JSCode.showError(txt: "You cannot build here as this property has no direct access to the public road.", duration: 10).response
            } catch ConstructionServicesError.financialTransactionProblem(let reason) {
                return JSCode.showError(txt: reason , duration: 10).response
            } catch {
                return JSCode.showError(txt: "Unexpected error [\(request.address ?? "")]", duration: 10).response
            }
            code.add(.closeWindow(windowIndex))
            return code.response
        }
        
        server.GET["/instantSell.js"] = { request, _ in
            request.disableKeepAlive = true
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
            guard property.ownerID == session.playerUUID else {
                code.add(.showError(txt: "You can sell only your properties.", duration: 10))
                return code.response
            }
            self.gameEngine.realEstateAgent.instantSell(address: address, playerUUID: session.playerUUID)
            code.add(.showSuccess(txt: "Successful sell transaction", duration: 5))
            code.add(.closeWindow(windowIndex))
            return code.response
        }
        
        server.GET["/instantApartmentSell.js"] = { request, _ in
            request.disableKeepAlive = true
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
                return JSCode.showError(txt: "Apartment \(propertyID) not found!", duration: 10).response
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
            guard apartment.ownerID == session.playerUUID else {
                code.add(.showError(txt: "You can sell only your apartment.", duration: 10))
                return code.response
            }
            self.gameEngine.realEstateAgent.instantApartmentSell(apartment, playerUUID: session.playerUUID)
            code.add(.showSuccess(txt: "You have sold \(apartment.name)", duration: 5))
            code.add(.loadHtml(windowIndex, htmlPath: "/propertyManager.html?\(apartment.address.asQueryParams)"))
            return code.response
        }
        
        server.GET["/loadApartmentDetails.js"] = { request, _ in
            request.disableKeepAlive = true

            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            
            guard let propertyID = request.queryParam("propertyID") else {
                return JSCode.showError(txt: "Invalid request! Missing propertyID.", duration: 10).response
            }
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    return JSCode.showError(txt: "Invalid request! Missing session ID.", duration: 10).response
            }
            let code = JSResponse()
            let editUrl = "manageApartment.html?playerSessionID=\(session.id)&propertyID=\(propertyID)"
            code.add(.loadHtmlInline(windowIndex, htmlPath: editUrl, targetID: "buildingDetails\(windowIndex)"))
            return code.response
        }
        
        server.GET["/rentApartment.js"] = { request, _ in
            request.disableKeepAlive = true
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
                return JSCode.showError(txt: "Apartment \(propertyID) not found!", duration: 10).response
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
            guard apartment.ownerID == session.playerUUID else {
                code.add(.showError(txt: "You can rent only your properties.", duration: 10))
                return code.response
            }
            if let _ = request.queryParam("unrent") {
                self.gameEngine.realEstateAgent.unrentApartment(apartment)
            } else {
                self.gameEngine.realEstateAgent.rentApartment(apartment)
            }
            code.add(.showSuccess(txt: "Action successed", duration: 5))
            
            let htmlUrl = "/propertyManager.html?\(apartment.address.asQueryParams)"
            let scriptUrl = "/loadApartmentDetails.js?propertyID=\(apartment.id)"
            code.add(.loadHtmlThenRunScripts(windowIndex, htmlPath: htmlUrl, scriptPaths: [scriptUrl]))
            return code.response
        }
        
        
        server.GET["/manageApartment.html"] = { request, _ in
            request.disableKeepAlive = true

            guard let windowIndex = request.queryParam("windowIndex") else {
                return .badRequest(.html("Invalid request! Missing window context."))
            }
            
            guard let propertyID = request.queryParam("propertyID") else {
                return .badRequest(.html("Invalid request! Missing propertyID."))
            }
            
            guard let apartment = Storage.shared.getApartment(id: propertyID) else {
                return .badRequest(.html("Apartment \(propertyID) not found!"))
            }
            
            guard let playerSessionID = request.queryParam("playerSessionID"),
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    return .badRequest(.html("Invalid request! Missing session ID."))
            }
        
            let apartmentView = Template(raw: ResourceCache.shared.getAppResource("templates/apartmentView.html"))

            var data = [String:String]()
            data["name"] = apartment.name
            let incomeTax = apartment.monthlyRentalFee * self.gameEngine.taxRates.incomeTax
            data["condition"] = "\(String(format: "%0.2f", apartment.condition))%"
            data["monthlyBills"] = apartment.monthlyBills.money
            data["monthlyBalance"] = (apartment.monthlyRentalFee - apartment.monthlyBills - incomeTax).money
            let estimatedPrice = self.gameEngine.realEstateAgent.estimateApartmentValue(apartment)
            
            if apartment.isRented {
                data["monthlyRentalFee"] = apartment.monthlyRentalFee.money
                data["taxRate"] = (self.gameEngine.taxRates.incomeTax*100).string
                data["monthlyIncomeTax"] = incomeTax.money
                data["actionTitle"] = "Kick out tenants"
                data["actionJS"] = JSCode.runScripts(windowIndex, paths: ["/rentApartment.js?unrent=true&\(apartment.address.asQueryParams)&propertyID=\(apartment.id)"]).js
                apartmentView.assign(variables: data, inNest: "rented")
            } else if apartment.ownerID != session.playerUUID {
                let buildingFee = apartment.monthlyBuildingFee
                let incomeTax = apartment.monthlyBuildingFee * self.gameEngine.taxRates.incomeTax
                data["monthlyIncome"] = buildingFee.money
                data["monthlyIncomeTax"] = incomeTax.money
                data["taxRate"] = (self.gameEngine.taxRates.incomeTax*100).string
                data["monthlyBalance"] = (apartment.monthlyBuildingFee - incomeTax).money
                apartmentView.assign(variables: data, inNest: "sold")
            } else {
                data["monthlyRentalFee"] = self.gameEngine.realEstateAgent.estimateRentFee(apartment).money
                data["estimatedValue"] = estimatedPrice.money
                data["instantSellPrice"] = (estimatedPrice * self.gameEngine.realEstateAgent.priceList.instantSellValue).money
                data["instantSellJS"] = JSCode.runScripts(windowIndex, paths: ["/instantApartmentSell.js?\(apartment.address.asQueryParams)&propertyID=\(apartment.id)"]).js
                let estimatedRent = self.gameEngine.realEstateAgent.estimateRentFee(apartment).money
                data["actionTitle"] = "Rent for \(estimatedRent)"
                data["actionJS"] = JSCode.runScripts(windowIndex, paths: ["/rentApartment.js?\(apartment.address.asQueryParams)&propertyID=\(apartment.id)"]).js
                apartmentView.assign(variables: data, inNest: "unrented")
            }
            
            return apartmentView.asResponse()
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
    
    
    private func buildingActions(building: ResidentialBuilding, windowIndex: String, session: PlayerSession) -> String {

        if building.isUnderConstruction, let constructionFinishMonth = building.constructionFinishMonth {
            return "Building is under construction. Your investment will finish on \(GameDate(monthIteration: constructionFinishMonth).text)"
        }
        
        let detailsDivID = "buildingDetails\(windowIndex)"
        
        let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManagerBuilding.html"))
        var templateVars: [String:String] = [:]
        templateVars["previewWidth"] = "\(120 * building.numberOfFlatsPerStorey)"
        templateVars["detailsID"] = detailsDivID
        
        
        let apartments = Storage.shared.getApartments(address: building.address)
        for i in (1...building.storeyAmount) {
            let storey = building.storeyAmount - i + 1
            
            var html = ""
            for flatNumber in (1...building.numberOfFlatsPerStorey) {
                var tdAttributes = [String:String]()
                
                var css = "";
                var incomeBalance = ""
                var editUrl = "loadApartmentDetails.js"
                
                if let apartment = (apartments.first { $0.storey == storey && $0.flatNumber == flatNumber }) {
                    if apartment.isRented {
                        // is rented
                        css = "background-color: #1F5E71;"
                        incomeBalance = (apartment.monthlyRentalFee - apartment.monthlyBills).money
                    } else if apartment.ownerID != session.playerUUID {
                        // is sold
                        css = "border: 1px solid #1F5E71;"
                        incomeBalance = "Sold"
                    } else {
                        // is unrented
                        css = "background-color: #70311E;"
                        incomeBalance = (-1 * apartment.monthlyBills).money
                    }
                    editUrl.append("?propertyID=\(apartment.id)")
                }
                let floated = Template.htmlNode(type: "div", attributes: ["class":"float-right"], content: incomeBalance)
                tdAttributes["style"] = "width: \(Int(100/building.numberOfFlatsPerStorey))%; padding: 5px; \(css)"
                tdAttributes["class"] = "hand"
                tdAttributes["onclick"] = JSCode.runScripts(windowIndex, paths: [editUrl]).js
                html.append(Template.htmlNode(type: "td", attributes: tdAttributes, content: "\(storey).\(flatNumber) \(floated)"))
            }
            template.assign(variables: ["tds": html], inNest: "storey")
        }
        template.assign(variables: templateVars)
        
        return template.output()
    }
}
