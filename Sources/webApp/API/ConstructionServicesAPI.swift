//
//  ConstructionServicesAPI.swift
//
//
//  Created by Tomasz Kucharski on 16/11/2021.
//

import Foundation

class ConstructionServicesAPI: RestAPI {
    enum API {
        case step1html
        case step2html
        case step3html
        case step4html
        case validateStep1js
        case validateStep2js
        case validateStep3js
        case startInvestment

        var url: String {
            switch self {
            case .step1html:
                return "/residentialInvestmentStep1.html"
            case .step2html:
                return "/residentialInvestmentStep2.html"
            case .step3html:
                return "/residentialInvestmentStep3.html"
            case .step4html:
                return "/residentialInvestmentStep4.html"
            case .validateStep1js:
                return "/validateStep1.js"
            case .validateStep2js:
                return "/validateStep2.js"
            case .validateStep3js:
                return "/validateStep3.js"
            case .startInvestment:
                return "/startResidentialbuildingInvestment.js"
            }
        }
    }

    override func setupEndpoints() {
        // MARK: startInvestment
        server.get[.startInvestment] = { request, _ in
            
            let code = JSResponse()
            guard let windowIndex = request.windowIndex else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            guard let playerSessionID = request.playerSessionID,
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                code.add(.closeWindow(windowIndex))
                code.add(.showError(txt: "Invalid request! Missing session ID.", duration: 10))
                return code.response
            }
            guard let investmentType = request.queryParams.get("type") else {
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
        server.get[.residentialBuildingInvestmentWizard] = { request, _ in
            
            guard let windowIndex = request.windowIndex else {
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
        self.server.get[API.step1html.url] = { request, _ in
            

            guard let windowIndex = request.windowIndex else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }

            let prechoiced = request.queryParams.get("storey")

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/constructionServices/residentialBuildingStep1.html"))
            for storey in [4, 6, 8, 10] {
                let offer = self.gameEngine.constructionServices.residentialBuildingOffer(landName: "", storeyAmount: storey, elevator: false, balconies: [])
                var data = [String: String]()
                data["storey"] = storey.string
                data["cost"] = offer.invoice.netValue.money
                if prechoiced == storey.string {
                    data["checked"] = "checked"
                }
                template.assign(variables: data, inNest: "storeyOption")
            }
            var data = [String: String]()
            data["submitUrl"] = API.validateStep1js.url.append(address)
            data["windowIndex"] = windowIndex
            template.assign(variables: data)
            return template.asResponse()
        }

        // MARK: validateBuildingStep1.js
        server.post[API.validateStep1js.url] = { request, _ in
            
            guard let windowIndex = request.windowIndex else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }

            guard let storey = request.formData["storey"] else {
                return self.jsError("Please choose storey amount")
            }
            guard [4, 6, 8, 10].contains(Int(storey)) else {
                return self.jsError("Invalid storey amount")
            }

            let js = JSResponse()
            js.add(.loadHtmlInline(windowIndex, htmlPath: API.step2html.url.append(address).append("storey", storey), targetID: PropertyManagerTopView.domID(windowIndex)))
            return js.response
        }

        // MARK: residentialInvestmentStep2.html
        self.server.get[API.step2html.url] = { request, _ in
            

            guard let windowIndex = request.windowIndex else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }
            guard let storeyTxt = request.queryParams.get("storey"), let storey = Int(storeyTxt) else {
                return self.htmlError("Missing storey amount")
            }

            let offer = self.gameEngine.constructionServices.residentialBuildingOffer(landName: "", storeyAmount: storey, elevator: false, balconies: [])

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/constructionServices/residentialBuildingStep2.html"))

            var data = [String: String]()
            data["storey"] = storeyTxt
            data["baseCost"] = offer.invoice.netValue.money
            data["elevatorCost"] = (self.gameEngine.constructionServices.priceList.residentialBuildingElevatorPricePerStorey * storey.double).money
            data["submitUrl"] = API.validateStep2js.url.append(address).append("storey", storeyTxt)
            data["previousJS"] = JSCode.loadHtmlInline(windowIndex, htmlPath: API.step1html.url.append(address).append("storey", storeyTxt), targetID: PropertyManagerTopView.domID(windowIndex)).js
            data["windowIndex"] = windowIndex

            let prechoice = request.queryParams.get("elevator")
            if prechoice == "true" {
                data["yesChecked"] = "checked"
            } else if prechoice == "false" {
                data["noChecked"] = "checked"
            }

            template.assign(variables: data)
            return template.asResponse()
        }

        // MARK: validateBuildingStep2.js
        server.post[API.validateStep2js.url] = { request, _ in
            
            guard let windowIndex = request.windowIndex else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }

            guard let storeyTxt = request.queryParams.get("storey") else {
                return self.jsError("Missing storey amount")
            }
            guard let elevator = request.formData["elevator"] else {
                return self.jsError("Please choose elevator option")
            }
            guard let _ = Bool(elevator) else {
                return self.jsError("Invalid elevator value")
            }

            let js = JSResponse()
            js.add(.loadHtmlInline(windowIndex, htmlPath: API.step3html.url.append(address).append("storey", storeyTxt).append("elevator", elevator), targetID: PropertyManagerTopView.domID(windowIndex)))
            return js.response
        }

        // MARK: residentialInvestmentStep3.html
        self.server.get[API.step3html.url] = { request, _ in
            

            guard let windowIndex = request.windowIndex else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }
            guard let storeyTxt = request.queryParams.get("storey"), let storey = Int(storeyTxt) else {
                return self.htmlError("Missing storey amount")
            }
            guard let elevatorTxt = request.queryParams.get("elevator") else {
                return self.htmlError("Missing storey amount")
            }
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/constructionServices/residentialBuildingStep3.html"))

            let prechoice = request.queryParams.get("balconies")?.components(separatedBy: ",").compactMap { ApartmentWindowSide(rawValue: $0) } ?? []

            for side in ApartmentWindowSide.allCases {
                let cost = storey.double * self.gameEngine.constructionServices.priceList.residentialBuildingBalconyCost
                var data = [String: String]()
                data["side"] = side.rawValue
                data["name"] = side.name
                data["cost"] = cost.money
                if prechoice.contains(side) {
                    data["checked"] = "checked"
                }
                template.assign(variables: data, inNest: "apartment")
            }
            var data = [String: String]()
            data["apartmentAmount"] = ApartmentWindowSide.allCases.count.string
            data["submitUrl"] = API.validateStep3js.url.append(address).append("storey", storeyTxt).append("elevator", elevatorTxt)
            data["previousJS"] = JSCode.loadHtmlInline(windowIndex, htmlPath: API.step2html.url.append(address).append("storey", storeyTxt).append("elevator", elevatorTxt), targetID: PropertyManagerTopView.domID(windowIndex)).js
            data["windowIndex"] = windowIndex
            template.assign(variables: data)
            return template.asResponse()
        }

        // MARK: validateBuildingStep3.js
        server.post[API.validateStep3js.url] = { request, _ in
            
            guard let windowIndex = request.windowIndex else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }

            guard let storeyTxt = request.queryParams.get("storey"), let storey = Int(storeyTxt) else {
                return self.jsError("Missing storey amount")
            }
            guard [2, 4, 6, 8, 10].contains(storey) else {
                return self.jsError("Invalid storey amount")
            }
            guard let elevatorTxt = request.queryParams.get("elevator"), let _ = Bool(elevatorTxt) else {
                return self.jsError("Invalid elevator value")
            }

            let formData = request.formData.dict
            var balconies: [ApartmentWindowSide] = []
            for balcony in ApartmentWindowSide.allCases {
                if let _ = formData[balcony.rawValue] {
                    balconies.append(balcony)
                }
            }

            let url = API.step4html.url
                .append(address)
                .append("storey", storeyTxt)
                .append("elevator", elevatorTxt)
                .append("balconies", balconies.map{ $0.rawValue }.joined(separator: ","))

            let js = JSResponse()
            js.add(.loadHtmlInline(windowIndex, htmlPath: url, targetID: PropertyManagerTopView.domID(windowIndex)))
            return js.response
        }

        // MARK: residentialInvestmentStep4.html
        self.server.get[API.step4html.url] = { request, _ in
            

            guard let windowIndex = request.windowIndex else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }
            guard let storeyTxt = request.queryParams.get("storey"), let storey = Int(storeyTxt) else {
                return self.htmlError("Missing storey amount")
            }
            guard let elevatorTxt = request.queryParams.get("elevator"), let elevator = Bool(elevatorTxt) else {
                return self.htmlError("Missing storey amount")
            }
            guard let balconiesTxt = request.queryParams.get("balconies") else {
                return self.htmlError("Missing balcony info")
            }
            let balconies = balconiesTxt.components(separatedBy: ",").compactMap { ApartmentWindowSide(rawValue: $0) }

            let offer = self.gameEngine.constructionServices.residentialBuildingOffer(landName: "", storeyAmount: storey, elevator: elevator, balconies: balconies)

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/constructionServices/residentialBuildingStep4.html"))
            var data = [String: String]()
            data["storey"] = storeyTxt
            data["balconies"] = balconiesTxt
            data["balconiesReadable"] = balconies.map{ $0.name }.chunked(by: 2).map{ $0.joined(separator: ", ") }.joined(separator: "<br>")
            data["elevator"] = elevatorTxt
            data["elevatorReadable"] = elevator ? "Yes" : "No"

            data["investmentCost"] = offer.invoice.netValue.money
            data["investmentTax"] = offer.invoice.tax.money
            data["investmentTotal"] = offer.invoice.total.money
            data["investmentDuration"] = "\(offer.duration) months"
            data["taxRate"] = (offer.invoice.taxRate * 100).rounded(toPlaces: 0).string

            let previousUrl = API.step3html.url
                .append(address).append("storey", storeyTxt)
                .append("elevator", elevatorTxt)
                .append("balconies", balconiesTxt)
            data["submitUrl"] = API.startInvestment.url
                .append(address).append("storey", storeyTxt)
                .append("elevator", elevatorTxt)
                .append("balconies", balconiesTxt)
            data["previousJS"] = JSCode.loadHtmlInline(windowIndex, htmlPath: previousUrl, targetID: PropertyManagerTopView.domID(windowIndex)).js
            data["windowIndex"] = windowIndex
            template.assign(variables: data)
            return template.asResponse()
        }

        // MARK: validateBuildingStep3.js
        server.post[API.startInvestment.url] = { request, _ in
            
            guard let windowIndex = request.windowIndex else {
                return self.jsError("Invalid request! Missing window context.")
            }
            let code = JSResponse()
            guard let playerSessionID = request.playerSessionID,
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                code.add(.closeWindow(windowIndex))
                code.add(.showError(txt: "Invalid request! Missing session ID.", duration: 10))
                return code.response
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            guard let storeyTxt = request.queryParams.get("storey"), let storey = Int(storeyTxt) else {
                return self.jsError("Missing storey amount")
            }
            guard [2, 4, 6, 8, 10].contains(storey) else {
                return self.jsError("Invalid storey amount")
            }
            guard let elevatorTxt = request.queryParams.get("elevator"), let elevator = Bool(elevatorTxt) else {
                return self.jsError("Invalid elevator value")
            }
            guard let balconiesTxt = request.queryParams.get("balconies") else {
                return self.jsError("Missing balconies")
            }
            let balconies = balconiesTxt.components(separatedBy: ",").compactMap { ApartmentWindowSide(rawValue: $0) }

            do {
                try self.gameEngine.constructionServices.startResidentialBuildingInvestment(address: address, playerUUID: session.playerUUID, storeyAmount: storey, elevator: elevator, balconies: balconies)

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
    }
}
