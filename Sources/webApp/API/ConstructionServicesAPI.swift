//
//  ConstructionServicesAPI.swift
//  
//
//  Created by Tomasz Kucharski on 16/11/2021.
//

import Foundation

class ConstructionServicesAPI: RestAPI {
    
    override func setupEndpoints() {
        
        // MARK: openLandManager
        server.GET[.startInvestment] = { request, _ in
            request.disableKeepAlive = true
            let code = JSResponse()
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    code.add(.closeWindow(windowIndex))
                    code.add(.showError(txt: "Invalid request! Missing session ID.", duration: 10))
                    return code.response
            }
            guard let investmentType = request.queryParam("type") else {
                return self.jsError("Invalid request! Missing investmentType.")
            }
            
            do {
                switch investmentType {
                case "road":
                    try self.gameEngine.constructionServices.startRoadInvestment(address: address, playerUUID: session.playerUUID)
                case "parking":
                    try self.gameEngine.constructionServices.startParkingInvestment(address: address, playerUUID: session.playerUUID)
                default:
                    return self.jsError("Invalid request! Invalid investmentType \(investmentType).")
                }
                
            } catch ConstructionServicesError.addressNotFound {
                return self.jsError("You can build only on an empty land.")
            } catch ConstructionServicesError.playerIsNotPropertyOwner {
                return self.jsError("You can invest only on your properties.")
            } catch ConstructionServicesError.noDirectAccessToRoad {
                return self.jsError("You cannot build here as this property has no direct access to the public road.")
            } catch ConstructionServicesError.financialTransactionProblem(let reason) {
                return self.jsError(reason.description)
            } catch {
                return self.jsError("Unexpected error [\(request.address ?? "")]")
            }
            code.add(.closeWindow(windowIndex))
            return code.response
        }
        
        // MARK: .residentialBuildingInvestmentWizard
        server.GET[.residentialBuildingInvestmentWizard] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            
            let js = JSResponse()
            js.add(.loadHtmlInline(windowIndex, htmlPath: "/residentialInvestmentStep1.html".append(address), targetID: PropertyManagerTopView.domID(windowIndex)))
            return js.response
        }
        
        
        // MARK: residentialInvestmentStep1.html
        self.server.GET["/residentialInvestmentStep1.html"] = { request, _ in
            request.disableKeepAlive = true
            
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/constructionServices/residentialBuildingStep1.html"))
            for storey in [4,6,8,10] {
                let offer = self.gameEngine.constructionServices.residentialBuildingOffer(landName: "", storeyAmount: storey, elevator: false, balconies: [])
                var data = [String:String]()
                data["storey"] = storey.string
                data["cost"] = offer.invoice.netValue.money
                template.assign(variables: data, inNest: "storeyOption")
            }
            var data = [String:String]()
            data["submitUrl"] = "/validateBuildingStep1.js".append(address)
            data["windowIndex"] = windowIndex
            template.assign(variables: data)
            return template.asResponse()
        }
        
        // MARK: validateBuildingStep1.js
        server.POST["/validateBuildingStep1.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            
            let formData = request.flatFormData()
            guard let storey = formData["storey"] else {
                return self.jsError("Please choose storey amount")
            }
            guard [4,6,8,10].contains(Int(storey)) else {
                return self.jsError("Invalid storey amount")
            }
            
            let js = JSResponse()
            js.add(.loadHtmlInline(windowIndex, htmlPath: "/residentialInvestmentStep2.html".append(address).appending("&storey=").appending(storey), targetID: PropertyManagerTopView.domID(windowIndex)))
            return js.response
        }
        
        
        // MARK: residentialInvestmentStep2.html
        self.server.GET["/residentialInvestmentStep2.html"] = { request, _ in
            request.disableKeepAlive = true
            
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }
            guard let storeyTxt = request.queryParam("storey"), let storey = Int(storeyTxt) else {
                return self.htmlError("Missing storey amount")
            }
            
            let offer = self.gameEngine.constructionServices.residentialBuildingOffer(landName: "", storeyAmount: storey, elevator: false, balconies: [])
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/constructionServices/residentialBuildingStep2.html"))

            var data = [String:String]()
            data["storey"] = storeyTxt
            data["baseCost"] = offer.invoice.netValue.money
            data["elevatorCost"] = (self.gameEngine.constructionServices.priceList.residentialBuildingElevatorPricePerStorey * storey.double).money
            data["submitUrl"] = "/validateBuildingStep2.js".append(address).appending("&storey=").appending(storeyTxt)
            data["windowIndex"] = windowIndex
            template.assign(variables: data)
            return template.asResponse()
        }
        
        // MARK: validateBuildingStep2.js
        server.POST["/validateBuildingStep2.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            
            guard let storeyTxt = request.queryParam("storey") else {
                return self.jsError("Missing storey amount")
            }
            let formData = request.flatFormData()
            guard let elevator = formData["elevator"] else {
                return self.jsError("Please choose elevator option")
            }
            guard let _ = Bool(elevator) else {
                return self.jsError("Invalid elevator value")
            }
            
            let js = JSResponse()
            js.add(.loadHtmlInline(windowIndex, htmlPath: "/residentialInvestmentStep3.html".append(address).appending("&storey=").appending(storeyTxt).appending("&elevator=").appending(elevator), targetID: PropertyManagerTopView.domID(windowIndex)))
            return js.response
        }
        
        // MARK: residentialInvestmentStep3.html
        self.server.GET["/residentialInvestmentStep3.html"] = { request, _ in
            request.disableKeepAlive = true
            
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }
            guard let storeyTxt = request.queryParam("storey"), let storey = Int(storeyTxt) else {
                return self.htmlError("Missing storey amount")
            }
            guard let elevatorTxt = request.queryParam("elevator") else {
                return self.htmlError("Missing storey amount")
            }
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/constructionServices/residentialBuildingStep3.html"))
            for side in ApartmentWindowSide.allCases {
                let cost = storey.double * self.gameEngine.constructionServices.priceList.residentialBuildingBalconyCost
                var data = [String:String]()
                data["side"] = side.name
                data["cost"] = cost.money
                template.assign(variables: data, inNest: "apartment")
            }
            var data = [String:String]()
            data["apartmentAmount"] = ApartmentWindowSide.allCases.count.string
            data["submitUrl"] = "/validateBuildingStep3.js".append(address)
            data["windowIndex"] = windowIndex
            template.assign(variables: data)
            return template.asResponse()
        }
    }
    
}
