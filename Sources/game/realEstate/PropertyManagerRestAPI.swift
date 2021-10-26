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
        
        // MARK: openPropertyInfo
        server.GET[.openPropertyInfo] = { request, _ in
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
            let ownerID = property.ownerUUID
            let owner = self.dataStore.find(uuid: ownerID)
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyInfo.html"))
            var data = [String:String]()
            data["type"] = property.type
            data["name"] = property.name
            data["owner"] = owner?.login ?? "nil"
            data["tileUrl"] = self.gameEngine.gameMap.getTile(address: address)?.type.image.path
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
                return JSCode.showError(txt: reason.description , duration: 10).response
            } catch {
                return JSCode.showError(txt: "Unexpected error [\(request.address ?? "")]", duration: 10).response
            }
            code.add(.closeWindow(windowIndex))
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
            guard apartment.ownerUUID == session.playerUUID else {
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
            let scriptUrl = "/loadApartmentDetails.js?propertyID=\(apartment.uuid)"
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
/*
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
                data["actionJS"] = JSCode.runScripts(windowIndex, paths: ["/rentApartment.js?unrent=true&\(apartment.address.asQueryParams)&propertyID=\(apartment.uuid)"]).js
                apartmentView.assign(variables: data, inNest: "rented")
            } else if apartment.ownerUUID != session.playerUUID {
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
                data["instantSellJS"] = JSCode.runScripts(windowIndex, paths: ["/instantApartmentSell.js?\(apartment.address.asQueryParams)&propertyID=\(apartment.uuid)"]).js
                let estimatedRent = self.gameEngine.realEstateAgent.estimateRentFee(apartment).money
                data["actionTitle"] = "Rent for \(estimatedRent)"
                data["actionJS"] = JSCode.runScripts(windowIndex, paths: ["/rentApartment.js?\(apartment.address.asQueryParams)&propertyID=\(apartment.uuid)"]).js
                apartmentView.assign(variables: data, inNest: "unrented")
            }
            */
            return apartmentView.asResponse()
        }
    }
    
    
    private func buildingActions(building: ResidentialBuilding, windowIndex: String, session: PlayerSession) -> String {

        if building.isUnderConstruction {
            let constructionFinishMonth = building.constructionFinishMonth
            return "Building is under construction. Your investment will finish on \(GameTime(constructionFinishMonth).text)"
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
                /*
                if let apartment = (apartments.first { $0.storey == storey && $0.flatNumber == flatNumber }) {
                    if apartment.isRented {
                        // is rented
                        css = "background-color: #1F5E71;"
                        incomeBalance = (apartment.monthlyRentalFee - apartment.monthlyBills).money
                    } else if apartment.ownerUUID != session.playerUUID {
                        // is sold
                        css = "border: 1px solid #1F5E71;"
                        incomeBalance = "Sold"
                    } else {
                        // is unrented
                        css = "background-color: #70311E;"
                        incomeBalance = (-1 * apartment.monthlyBills).money
                    }
                    editUrl.append("?propertyID=\(apartment.uuid)")
                }
                 */
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
