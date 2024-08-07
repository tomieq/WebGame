//
//  PropertyManagerRestAPI.swift
//
//
//  Created by Tomasz Kucharski on 24/03/2021.
//

import Foundation
import Swifter

class PropertyManagerRestAPI: RestAPI {
    override func setupEndpoints() {
        // MARK: openPropertyInfo
        server.get[.openPropertyInfo] = { request, _ in
            
            guard let windowIndex = request.windowIndex else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            if let tile = self.gameEngine.gameMap.getTile(address: address), tile.isParking() {
                js.add(ParkingRestAPI.jsForHighlightParkingArea(address: address, parkingClientCalculator: self.gameEngine.parkingClientCalculator))
            }
            js.add(.loadHtml(windowIndex, htmlPath: "/propertyInfo.html?\(address.asQueryParams)"))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }

        server.get["/propertyInfo.html"] = { request, _ in
            
            guard let _ = request.windowIndex else {
                return .badRequest(.html("Invalid request! Missing window context."))
            }
            guard let address = request.mapPoint else {
                return .badRequest(.html("Invalid request! Missing address."))
            }
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return .badRequest(.html("Property at \(address.readable) not found!"))
            }
            let ownerID = property.ownerUUID
            let owner: Player? = self.dataStore.find(uuid: ownerID)

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyInfo.html"))
            var data = [String: String]()
            data["type"] = property.type
            data["name"] = property.name
            data["owner"] = owner?.login ?? "nil"
            data["tileUrl"] = self.gameEngine.gameMap.getTile(address: address)?.type.image.path
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }

        // MARK: propertyWalletBalance
        server.get[.propertyWalletBalance] = { request, _ in
            
            guard let playerSessionID = request.playerSessionID,
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return self.htmlError("Invalid request! Missing session ID.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }
            guard let property = self.gameEngine.realEstateAgent.getProperty(address: address) else {
                return self.htmlError("Property at \(address.readable) not found!")
            }
            let ownerID = property.ownerUUID
            guard session.playerUUID == ownerID else {
                return self.htmlError("Property at \(address.readable) is not yours!")
            }
            let balanceView = PropertyBalanceView()
            balanceView.setMonthlyCosts(self.gameEngine.propertyBalanceCalculator.getMontlyCosts(address: address))
            balanceView.setMonthlyIncome(self.gameEngine.propertyBalanceCalculator.getMonthlyIncome(address: address))
            balanceView.setProperty(property)
            return balanceView.output().asResponse
        }

        server.get["/loadApartmentDetails.js"] = { request, _ in
            

            guard let windowIndex = request.windowIndex else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }

            guard let propertyID = request.queryParams.get("propertyID") else {
                return JSCode.showError(txt: "Invalid request! Missing propertyID.", duration: 10).response
            }
            guard let playerSessionID = request.playerSessionID,
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return JSCode.showError(txt: "Invalid request! Missing session ID.", duration: 10).response
            }
            let code = JSResponse()
            let editUrl = "manageApartment.html?playerSessionID=\(session.id)&propertyID=\(propertyID)"
            code.add(.loadHtmlInline(windowIndex, htmlPath: editUrl, targetID: "buildingDetails\(windowIndex)"))
            return code.response
        }
        /*
         server.get["/rentApartment.js"] = { request, _ in
             
             let code = JSResponse()
             guard let windowIndex = request.windowIndex else {
                 return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
             }
             guard let address = request.mapPoint else {
                 return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
             }

             guard let propertyID = request.queryParams.get("propertyID") else {
                 return JSCode.showError(txt: "Invalid request! Missing propertyID.", duration: 10).response
             }

             guard let apartment = Storage.shared.getApartment(id: propertyID) else {
                 return JSCode.showError(txt: "Apartment \(propertyID) not found!", duration: 10).response
             }
             guard apartment.address == address else {
                 return JSCode.showError(txt: "Property address mismatch.", duration: 10).response
             }

             guard let playerSessionID = request.playerSessionID,
                 let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                     code.add(.closeWindow(windowIndex))
                     code.add(.showError(txt: "Invalid request! Missing session ID.", duration: 10))
                     return code.response
             }
             guard apartment.ownerUUID == session.playerUUID else {
                 code.add(.showError(txt: "You can rent only your properties.", duration: 10))
                 return code.response
             }
             if let _ = request.queryParams.get("unrent") {
                 //self.gameEngine.realEstateAgent.unrentApartment(apartment)
             } else {
                 //self.gameEngine.realEstateAgent.rentApartment(apartment)
             }
             code.add(.showSuccess(txt: "Action successed", duration: 5))

             let htmlUrl = "/propertyManager.html?\(apartment.address.asQueryParams)"
             let scriptUrl = "/loadApartmentDetails.js?propertyID=\(apartment.uuid)"
             code.add(.loadHtmlThenRunScripts(windowIndex, htmlPath: htmlUrl, scriptPaths: [scriptUrl]))
             return code.response
         }

         server.get["/manageApartment.html"] = { request, _ in
             

             guard let windowIndex = request.windowIndex else {
                 return .badRequest(.html("Invalid request! Missing window context."))
             }

             guard let propertyID = request.queryParams.get("propertyID") else {
                 return .badRequest(.html("Invalid request! Missing propertyID."))
             }

             guard let apartment = Storage.shared.getApartment(id: propertyID) else {
                 return .badRequest(.html("Apartment \(propertyID) not found!"))
             }

             guard let playerSessionID = request.playerSessionID,
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
         }*/
    }

    /*
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
     }*/
}
