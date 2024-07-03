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
        self.server.get[.openFootballPitch] = { request, _ in
            request.disableKeepAlive = true

            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            let js = JSResponse()
            js.add(.openWindow(name: "Football pitch", path: "/initFootballPitch.js".append(address), width: 400, height: 435, point: address, singletonID: address.asQueryParams))

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
        self.server.get["/initFootballPitch.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.windowIndex else {
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
        self.server.get["/footballPitchInfo.html"] = { request, _ in
            request.disableKeepAlive = true

            guard let windowIndex = request.windowIndex else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let playerSessionID = request.playerSessionID,
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return self.htmlError("Invalid request! Missing session ID.")
            }
            let template = Template(raw: ResourceCache.shared.getAppResource("templates/footballPitchInfo.html"))
            let bookie = self.gameEngine.footballBookie

            if let lastMatch = bookie.lastMonthMatch {
                var data = [String: String]()
                data["team"] = lastMatch.team1
                data["team2"] = lastMatch.team2
                data["referee"] = lastMatch.referee
                data["goals1"] = lastMatch.goals?.team1.string ?? "0"
                data["goals2"] = lastMatch.goals?.team2.string ?? "0"
                template.assign(variables: data, inNest: "lastMatch")
            }
            let match = bookie.upcomingMatch
            var data = [String: String]()
            data["tileUrl"] = TileType.smallFootballPitch.image.path
            data["team"] = match.team1
            data["team2"] = match.team2
            data["referee"] = match.referee
            data["windowIndex"] = windowIndex

            template.assign(variables: data)
            if let bet = bookie.getBet(playerUUID: session.playerUUID) {
                func who() -> String {
                    switch bet.expectedResult {
                    case .draw:
                        return "draw"
                    case .team1Win:
                        return match.team1
                    case .team2Win:
                        return match.team2
                    }
                }
                var data = [String: String]()
                data["money"] = bet.money.money
                data["who"] = who()
                data["win"] = (bet.money * bookie.upcomingMatch.resultRatio(bet.expectedResult)).money
                template.assign(variables: data, inNest: "betInfo")
                let ivestigation = self.gameEngine.police.investigations.filter{ $0.type == .footballMatchBribery }
                if !bookie.referee.didAlreadyTryBribe(playerUUID: session.playerUUID), ivestigation.isEmpty {
                    data = [String: String]()
                    data["referee"] = match.referee
                    data["contactRefereeJS"] = JSCode.loadHtml(windowIndex, htmlPath: "/contactReferee.html?matchUUID=\(match.uuid)").js
                    template.assign(variables: data, inNest: "bribe")
                }
            } else {
                var data = [String: String]()
                data["makeBetUrl"] = JSCode.loadHtml(windowIndex, htmlPath: "/makeBetForm.html?matchUUID=\(match.uuid)").js
                template.assign(variables: data, inNest: "makeBet")
            }
            return template.asResponse()
        }

        // MARK: betForm.html
        self.server.get["/makeBetForm.html"] = { request, _ in
            request.disableKeepAlive = true

            guard let windowIndex = request.windowIndex else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let matchUUID = request.queryParams.get("matchUUID") else {
                return self.htmlError("Invalid request! Missing match ID.")
            }
            let match = self.gameEngine.footballBookie.upcomingMatch
            guard match.uuid == matchUUID else {
                return self.htmlError("The match is over. You can not bet now. Try next game.")
            }

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/makeBetForm.html"))
            var data = [String: String]()
            data["team"] = match.team1
            data["team2"] = match.team2
            data["referee"] = match.referee
            data["matchUUID"] = matchUUID
            data["windowIndex"] = windowIndex
            data["submitUrl"] = "/makeBet.js"
            data["draw"] = FootballMatchResult.draw.rawValue
            data["team2Won"] = FootballMatchResult.team2Win.rawValue
            data["team1Won"] = FootballMatchResult.team1Win.rawValue
            data["team1winRatio"] = match.team1WinsRatio.rounded(toPlaces: 2).string
            data["team2winRatio"] = match.team2WinsRatio.rounded(toPlaces: 2).string
            data["drawRatio"] = match.drawRatio.rounded(toPlaces: 2).string
            template.assign(variables: data)
            return template.asResponse()
        }

        // MARK: makeBet.js
        self.server.post["/makeBet.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.playerSessionID,
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return self.jsError("Invalid request! Missing session ID.")
            }
            guard let windowIndex = request.windowIndex else {
                return self.jsError("Invalid request! Missing window context.")
            }
            struct MakeBet: Decodable {
                let matchUUID: String
                let money: String
                let result: String
            }
            guard let betForm: MakeBet = try? request.formData.decode() else {
                return self.jsError("Please provide data for bet")
            }
            guard let money = Double(betForm.money.replacingOccurrences(of: " ", with: "")) else {
                return self.jsError("Please provide the amount of money")
            }
            guard let result = FootballMatchResult(rawValue: betForm.result) else {
                return self.jsError("Please decide what you bet")
            }
            let match = self.gameEngine.footballBookie.upcomingMatch
            guard match.uuid == betForm.matchUUID else {
                return self.jsError("The match is over. You can not do any action now. Try with next game.")
            }
            let bookie = self.gameEngine.footballBookie
            let bet = FootballBet(matchUUID: betForm.matchUUID, playerUUID: session.playerUUID, money: money, expectedResult: result)
            do {
                try bookie.makeBet(bet: bet)
                let js = JSResponse()
                js.add(.closeWindow(windowIndex))
                return js.response
            } catch let error as MakeBetError {
                return self.jsError(error.description)
            } catch {
                return self.jsError(error.localizedDescription)
            }
        }

        // MARK: contactReferee.html
        self.server.get["/contactReferee.html"] = { request, _ in
            request.disableKeepAlive = true

            guard let windowIndex = request.windowIndex else {
                return self.htmlError("Invalid request! Missing window context.")
            }
            guard let matchUUID = request.queryParams.get("matchUUID") else {
                return self.htmlError("Invalid request! Missing match ID.")
            }
            let match = self.gameEngine.footballBookie.upcomingMatch
            guard match.uuid == matchUUID else {
                return self.htmlError("The match is over. You can not bet now. Try next game.")
            }

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/makeRefereeOfferForm.html"))
            var data = [String: String]()
            data["team"] = match.team1
            data["team2"] = match.team2
            data["referee"] = match.referee
            data["matchUUID"] = matchUUID
            data["windowIndex"] = windowIndex
            data["submitUrl"] = "/makeRefereeOfferForm.js"
            template.assign(variables: data)
            return template.asResponse()
        }

        // MARK: makeRefereeOfferForm.js
        self.server.post["/makeRefereeOfferForm.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let playerSessionID = request.playerSessionID,
                  let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                return self.jsError("Invalid request! Missing session ID.")
            }
            guard let windowIndex = request.windowIndex else {
                return self.jsError("Invalid request! Missing window context.")
            }
            struct Offer: Decodable {
                let matchUUID: String
                let money: String
            }
            guard let offerForm: Offer = try? request.formData.decode() else {
                return self.jsError("Please provide data for offer")
            }
            guard let money = Double(offerForm.money.replacingOccurrences(of: " ", with: "")) else {
                return self.jsError("Please provide the amount of money")
            }
            let referee = self.gameEngine.footballBookie.referee
            let js = JSResponse()
            do {
                try referee.bribe(playerUUID: session.playerUUID, matchUUID: offerForm.matchUUID, amount: money)
            } catch let error as RefereeError {
                js.add(.showError(txt: error.description, duration: 10))
            } catch {
                js.add(.showError(txt: error.localizedDescription, duration: 10))
            }
            js.add(.closeWindow(windowIndex))
            return js.response
        }
    }
}
