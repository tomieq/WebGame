//
//  PublicPlacesAPI.swift
//  
//
//  Created by Tomasz Kucharski on 27/10/2021.
//

import Foundation

class PublicPlacesAPI: RestAPI {
    override func setupEndpoints() {

        // MARK: openFootballPitch
        self.server.GET[.openFootballPitch] = { request, _ in
            request.disableKeepAlive = true
            
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.openWindow(name: "Football pitch", path: "/initFootballPitch.js".append(address), width: 400, height: 420, point: address, singletonID: address.asQueryParams))
            
            if let tile = self.gameEngine.gameMap.getTile(address: address) {
                switch tile.type {
                case .footballPitch(let side):
                    var points: [MapPoint] = [address]
                    switch side {
                    case .leftTop:
                        points.append(address.move(.right))
                        points.append(address.move(.down))
                        points.append(address.move(.down).move(.right))
                    case .rightTop:
                        points.append(address.move(.left))
                        points.append(address.move(.down))
                        points.append(address.move(.down).move(.left))
                    case .leftBottom:
                        points.append(address.move(.right))
                        points.append(address.move(.up))
                        points.append(address.move(.up).move(.right))
                    case .rightBottom:
                        points.append(address.move(.left))
                        points.append(address.move(.up))
                        points.append(address.move(.up).move(.left))
                    }
                    js.add(.highlightPoints(points, color: "yellow"))
                default:
                    return self.jsError("Invalid request! Not a football pitch!")
                }
            }
            
            
            return js.response
        }
        
        // MARK: initFootballPitch.js
        self.server.GET["/initFootballPitch.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/footballPitchInfo.html?&\(address.asQueryParams)"))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }
        
        // MARK: footballPitchInfo.html
        self.server.GET["/footballPitchInfo.html"] = { request, _ in
            request.disableKeepAlive = true

            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/footballPitchInfo.html"))
            
            
            if let lastMatch = self.gameEngine.footballBookie.lastMonthMatch {
                var data = [String:String]()
                data["team"] = lastMatch.team1
                data["team2"] = lastMatch.team2
                data["referee"] = lastMatch.referee
                data["goals1"] = lastMatch.goals?.team1.string ?? "0"
                data["goals2"] = lastMatch.goals?.team2.string ?? "0"
                template.assign(variables: data, inNest: "lastMatch")
            }
            let match = self.gameEngine.footballBookie.upcomingMatch
            var data = [String:String]()
            data["tileUrl"] = TileType.smallFootballPitch.image.path
            data["team"] = match.team1
            data["team2"] = match.team2
            data["referee"] = match.referee
            data["windowIndex"] = windowIndex
            data["makeBetUrl"] = JSCode.loadHtml(windowIndex, htmlPath: "/makeBetForm.html?matchUUID=\(match.uuid)").js
            template.assign(variables: data)
            return template.asResponse()
        }
        
        
        // MARK: betForm.html
        self.server.GET["/makeBetForm.html"] = { request, _ in
            request.disableKeepAlive = true

            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let matchUUID = request.queryParam("matchUUID") else {
                return self.htmlError("Invalid request! Missing match ID.")
            }
            let match = self.gameEngine.footballBookie.upcomingMatch
            guard match.uuid == matchUUID else {
                return self.htmlError("The match is over. You can not bet now. Try next game.")
            }
            
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/makeBetForm.html"))
            var data = [String:String]()
            data["team"] = match.team1
            data["team2"] = match.team2
            data["referee"] = match.referee
            data["matchUUID"] = matchUUID
            data["windowIndex"] = windowIndex
            data["submitUrl"] = "/makeBet.js"
            data["draw"] = FootballMatchResult.draw.rawValue
            data["team2Won"] = FootballMatchResult.team2Won.rawValue
            data["team1Won"] = FootballMatchResult.team1Won.rawValue
            data["team1winRatio"] = match.team1WinsRatio.rounded(toPlaces: 2).string
            data["team2winRatio"] = match.team2WinsRatio.rounded(toPlaces: 2).string
            data["drawRatio"] = match.drawRatio.rounded(toPlaces: 2).string
            template.assign(variables: data)
            return template.asResponse()
        }
        
        // MARK: makeBet.js
        self.server.POST["/makeBet.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    return self.htmlError("Invalid request! Missing session ID.")
            }
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            let formData = request.flatFormData()
            guard let matchUUID = formData["matchUUID"] else {
                return self.jsError("Invalid request! Missing match ID.")
            }
            guard let moneyString = formData["money"], let money = Double(moneyString) else {
                return self.jsError("Please provide the amount of money")
            }
            guard let resultString = formData["result"], let result = FootballMatchResult(rawValue: resultString) else {
                return self.jsError("Please decide what you bet")
            }
            let match = self.gameEngine.footballBookie.upcomingMatch
            guard match.uuid == matchUUID else {
                return self.htmlError("The match is over. You can not bet now. Try next game.")
            }
            let bookie = self.gameEngine.footballBookie
            let bet = FootballBet(matchUUID: matchUUID, playerUUID: session.playerUUID, money: money, expectedResult: result)
            do {
                try bookie.makeBet(bet: bet)
                let js = JSResponse()
                js.add(.showSuccess(txt: "Your bet was accepted", duration: 5))
                js.add(.closeWindow(windowIndex))
                return js.response
            } catch let error as MakeBetError {
                return self.jsError(error.description)
            } catch {
                return self.jsError(error.localizedDescription)
            }
            
        }
    }
}
