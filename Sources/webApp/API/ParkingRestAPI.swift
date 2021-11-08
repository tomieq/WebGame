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
            js.add(.openWindow(name: "Parking Manager", path: "/initParkingManager.js".append(address), width: 580, height: 480, singletonID: address.asQueryParams))
            var points = self.gameEngine.gameMap.getNeighbourAddresses(to: address, radius: 1)
            points.append(contentsOf: self.gameEngine.gameMap.getNeighbourAddresses(to: address, radius: 2))
            js.add(.highlightPoints(points, color: "green"))
            let competitors = self.gameEngine.parkingBusiness.getParkingsAroundAddress(address)
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
            let view = PropertyManagerTopView(windowIndex: windowIndex)
            let domID = PropertyManagerTopView.domID(windowIndex)
            view.addTab("Wallet balance", onclick: .loadHtmlInline(windowIndex, htmlPath: "parkingBalance.html".append(address), targetID: domID))
            view.addTab("Security", onclick: .loadHtmlInline(windowIndex, htmlPath: "parkingSecurity.html".append(address), targetID: domID))
            view.addTab("Insurance", onclick: .loadHtmlInline(windowIndex, htmlPath: "parkingInsurance.html".append(address), targetID: domID))
            view.addTab("Damages", onclick: .loadHtmlInline(windowIndex, htmlPath: "parkingDamages.html".append(address), targetID: domID))
            view.addTab("Advertising", onclick: .loadHtmlInline(windowIndex, htmlPath: "parkingAdvertising.html".append(address), targetID: domID))
            view.addTab("Sell", onclick: .loadHtmlInline(windowIndex, htmlPath: RestEndpoint.propertySellStatus.append(address), targetID: domID))
            
            
            if parking.isUnderConstruction {
                view.setPropertyType("\(parking.type) - under construction")
                    .setTileImage(TileType.parkingUnderConstruction.image.path)
                
            } else {
                view.setPropertyType(parking.type)
                    .setTileImage(TileType.parking(type: .leftConnection).image.path)
            }
            
            view.addTip("The more buildings/facilities around, the more customers you get.")
                .addTip("If there is more parkings in the area, the market is shared between them.")
                .addTip("It's best if your parking business is the only one in the area.")
                .addTip("The area coverage of your parking lot is marked with green and the competitors in red.")
            
            let balanceView = PropertyBalanceView()
            balanceView.setMonthlyCosts(self.gameEngine.propertyBalanceCalculator.getMontlyCosts(address: address))
            balanceView.setMonthlyIncome(self.gameEngine.propertyBalanceCalculator.getMonthlyIncome(address: address))
            balanceView.setProperty(parking)

            view.setInitialContent(html: balanceView.output())
            
            
            return view.output().asResponse
        }
        
        // MARK: parkingBalance.html
        server.GET["/parkingBalance.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    return self.htmlError("Invalid request! Missing session ID.")
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
            let balanceView = PropertyBalanceView()
            balanceView.setMonthlyCosts(self.gameEngine.propertyBalanceCalculator.getMontlyCosts(address: address))
            balanceView.setMonthlyIncome(self.gameEngine.propertyBalanceCalculator.getMonthlyIncome(address: address))
            balanceView.setProperty(parking)
            return balanceView.output().asResponse
        }
        
        // MARK: parkingSecurity.html
        server.GET["/parkingSecurity.html"] = { request, _ in
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
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManager/parking/parkingSecurity.html"))
            var data: [String: String] = [:]
            data["windowIndex"] = windowIndex
            data["submitUrl"] = "/updateParkingSecurity.js".append(address)
            template.assign(variables: data)
            
            for security in ParkingSecurity.allCases {
                var data: [String: String] = [:]
                data["name"] = security.name
                data["value"] = security.rawValue
                data["money"] = security.monthlyFee.money
                data["effectiveness"] = security.effectiveneness.string
                if parking.security == security {
                    data["checked"] = "checked"
                }
                template.assign(variables: data, inNest: "security")
            }
            
            for insurance in ParkingInsurance.allCases {
                var data: [String: String] = [:]
                data["name"] = insurance.name
                data["value"] = insurance.rawValue
                data["money"] = insurance.monthlyFee.money
                data["limit"] = insurance.damageCoverLimit.money
                if parking.insurance == insurance {
                    data["checked"] = "checked"
                }
                template.assign(variables: data, inNest: "insurance")
            }
            return template.asResponse()
        }
        
        // MARK: updateParkingSecurity.js
        server.POST["updateParkingSecurity.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    return self.jsError("Invalid request! Missing session ID.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            guard let parking: Parking = self.dataStore.find(address: address) else {
                return self.jsError("Property at \(address.description) not found!")
            }
            let ownerID = parking.ownerUUID
            guard session.playerUUID == ownerID else {
                return self.jsError("Property at \(address.description) is not yours!")
            }
            
            let formData = request.flatFormData()
            guard let securityString = formData["security"], let security = ParkingSecurity(rawValue: securityString) else {
                return self.jsError("Security value not set!")
            }
            let mutation = ParkingMutation(uuid: parking.uuid, attributes: [.security(security)])
            self.gameEngine.dataStore.update(mutation)
            let js = JSResponse()
            if security == .none {
                js.add(.showWarning(txt: "Security policy cancelled for \(parking.name) located \(parking.readableAddress)", duration: 10))
            } else {
                let text = "New security options applied for \(parking.name) located \(parking.readableAddress)"
                self.gameEngine.notify(playerUUID: session.playerUUID, UINotification(text: text, level: .success, duration: 10, icon: .security))
            }
            return js.response
        }
        
        // MARK: parkingInsurance.html
        server.GET["/parkingInsurance.html"] = { request, _ in
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
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManager/parking/parkingInsurance.html"))
            var data: [String: String] = [:]
            data["windowIndex"] = windowIndex
            data["submitUrl"] = "/updateParkingInsurance.js".append(address)
            template.assign(variables: data)
            
            for insurance in ParkingInsurance.allCases {
                var data: [String: String] = [:]
                data["name"] = insurance.name
                data["value"] = insurance.rawValue
                data["money"] = insurance.monthlyFee.money
                data["limit"] = insurance.damageCoverLimit.money
                if parking.insurance == insurance {
                    data["checked"] = "checked"
                }
                template.assign(variables: data, inNest: "insurance")
            }
            return template.asResponse()
        }
        
        // MARK: updateParkingInsurance.js
        server.POST["updateParkingInsurance.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    return self.jsError("Invalid request! Missing session ID.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            guard let parking: Parking = self.dataStore.find(address: address) else {
                return self.jsError("Property at \(address.description) not found!")
            }
            let ownerID = parking.ownerUUID
            guard session.playerUUID == ownerID else {
                return self.jsError("Property at \(address.description) is not yours!")
            }
            
            let formData = request.flatFormData()
            guard let insuranceString = formData["insurance"], let insurance = ParkingInsurance(rawValue: insuranceString) else {
                return self.jsError("Insurance value not set!")
            }
            let mutation = ParkingMutation(uuid: parking.uuid, attributes: [.insurance(insurance)])
            self.gameEngine.dataStore.update(mutation)
            let js = JSResponse()
            if insurance == .none {
                js.add(.showWarning(txt: "Insurance policy cancelled for \(parking.name) located \(parking.readableAddress)", duration: 10))
            } else {
                let text = "New insurance options applied for \(parking.name) located \(parking.readableAddress)"
                self.gameEngine.notify(playerUUID: session.playerUUID, UINotification(text: text, level: .success, duration: 10, icon: .insurance))
            }
            return js.response
        }
        
        // MARK: parkingDamages.html
        server.GET["/parkingDamages.html"] = { request, _ in
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
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManager/parking/parkingDamages.html"))
            var data: [String: String] = [:]
            data["trustLevel"] = (parking.trustLevel * 100).int.string
            template.assign(variables: data)
            let damages = self.gameEngine.parkingBusiness.getDamages(address: address)
            if damages.isEmpty {
                template.assign(variables: [:], inNest: "noDamages")
            } else {
                for damage in damages {
                    var data: [String: String] = [:]
                    data["date"] = GameTime(damage.accidentMonth).text
                    data["car"] = damage.car
                    data["type"] = damage.type.name
                    data["money"] = damage.fixPrice.money
                    data["status"] = damage.status.name
                    if damage.status.isClosed {
                        data["css"] = "background-green"
                    } else {
                        data["css"] = "background-red"
                    }
                    template.assign(variables: data, inNest: "damage")
                }
            }
            return template.asResponse()
        }
        
        // MARK: parkingAdvertising.html
        server.GET["/parkingAdvertising.html"] = { request, _ in
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
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManager/parking/parkingAdvertising.html"))
            var data: [String: String] = [:]
            data["windowIndex"] = windowIndex
            data["submitUrl"] = "/updateParkingAdvertisement.js".append(address)
            data["trustLevel"] = (parking.trustLevel * 100).int.string
            template.assign(variables: data)
            
            for advertising in ParkingAdvertising.allCases {
                var data: [String: String] = [:]
                data["name"] = advertising.name
                data["value"] = advertising.rawValue
                data["money"] = advertising.monthlyFee.money
                let effectiveness = (advertising.monthlyTrustGain * 100).int
                data["effectiveness"] = effectiveness > 0 ? "~\(effectiveness)" : effectiveness.string
                if parking.advertising == advertising {
                    data["checked"] = "checked"
                }
                template.assign(variables: data, inNest: "advert")
            }
            return template.asResponse()
        }
        
        // MARK: updateParkingAdvertisement.js
        server.POST["updateParkingAdvertisement.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    return self.jsError("Invalid request! Missing session ID.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            guard let parking: Parking = self.dataStore.find(address: address) else {
                return self.jsError("Property at \(address.description) not found!")
            }
            let ownerID = parking.ownerUUID
            guard session.playerUUID == ownerID else {
                return self.jsError("Property at \(address.description) is not yours!")
            }
            
            let formData = request.flatFormData()
            guard let advertisementString = formData["advertisement"], let advertisement = ParkingAdvertising(rawValue: advertisementString) else {
                return self.jsError("Advertisement value not set!")
            }
            let mutation = ParkingMutation(uuid: parking.uuid, attributes: [.advertising(advertisement)])
            self.gameEngine.dataStore.update(mutation)
            let js = JSResponse()
            js.add(.showSuccess(txt: "New advertisement options applied!", duration: 10))
            return js.response
        }
    }

}
