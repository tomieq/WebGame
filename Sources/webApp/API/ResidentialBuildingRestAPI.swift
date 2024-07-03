//
//  ResidentialBuildingRestAPI.swift
//
//
//  Created by Tomasz Kucharski on 26/10/2021.
//

import Foundation

class ResidentialBuildingRestAPI: RestAPI {
    override func setupEndpoints() {
        // MARK: openBuildingManager
        server.get[.openBuildingManager] = { request, _ in
            request.disableKeepAlive = true

            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.openWindow(name: "Residential Building", path: "/initBuildingManager.js".append(address), width: 680, height: 500, singletonID: address.asQueryParams))
            return js.response
        }

        // MARK: initBuildingManager.js
        server.get["/initBuildingManager.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.windowIndex else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/buildingManager.html?\(address.asQueryParams)"))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }

        // MARK: buildingManager.html
        server.get["/buildingManager.html"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.playerSessionID,
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return self.htmlError("Invalid request! Missing session ID.")
            }
            guard let windowIndex = request.windowIndex else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.htmlError("Invalid request! Missing address.")
            }
            guard let building: ResidentialBuilding = self.dataStore.find(address: address) else {
                return self.htmlError("Property at \(address.description) not found!")
            }
            let ownerID = building.ownerUUID
            guard session.playerUUID == ownerID else {
                return self.htmlError("Property at \(address.description) is not yours!")
            }

            let view = PropertyManagerTopView(windowIndex: windowIndex)
            let domID = PropertyManagerTopView.domID(windowIndex)
            view.addTab("Wallet balance", onclick: .loadHtmlInline(windowIndex, htmlPath: RestEndpoint.propertyWalletBalance.append(address), targetID: domID))
            view.addTab("Sell options", onclick: .loadHtmlInline(windowIndex, htmlPath: RestEndpoint.propertySellStatus.append(address), targetID: domID))
            view.addTab("Investments", onclick: .loadHtmlInline(windowIndex, htmlPath: "buildingInvestments.html".append(address), targetID: domID))

            if building.isUnderConstruction {
                view.setPropertyType("\(building.type) - under construction")
                    .setTileImage(TileType.buildingUnderConstruction(size: building.storeyAmount).image.path)

            } else {
                view.setPropertyType(building.type)
                    .setTileImage(building.mapTile.image.path)
            }

            view.addTip("Earn money on renting apartments or sell them.")

            let balanceView = PropertyBalanceView()
            balanceView.setMonthlyCosts(self.gameEngine.propertyBalanceCalculator.getMontlyCosts(address: address))
            balanceView.setMonthlyIncome(self.gameEngine.propertyBalanceCalculator.getMonthlyIncome(address: address))
            balanceView.setProperty(building)

            view.setInitialContent(html: balanceView.output())
            return view.output().asResponse
        }
    }
}
