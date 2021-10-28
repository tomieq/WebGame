//
//  PublicPlacesAPI.swift
//  
//
//  Created by Tomasz Kucharski on 27/10/2021.
//

import Foundation

class PublicPlacesAPI: RestAPI {
    override func setupEndpoints() {

        // MARK: openRoadInfo
        self.server.GET[.openFootballPitch] = { request, _ in
            request.disableKeepAlive = true
            
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.openWindow(name: "Football pitch", path: "/initFootballPitch.js".append(address), width: 400, height: 310, point: address, singletonID: address.asQueryParams))
            
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
                    return JSCode.showError(txt: "Invalid request! Not a football pitch!", duration: 10).response
                }
            }
            
            
            return js.response
        }
        
        // MARK: openRoadInfo
        self.server.GET["/initFootballPitch.js"] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/footballPitchInfo.html?&\(address.asQueryParams)"))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }
        
        // MARK: roadInfo.html
        self.server.GET["/footballPitchInfo.html"] = { request, _ in
            request.disableKeepAlive = true

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/footballPitchInfo.html"))
            var data = [String:String]()
            data["tileUrl"] = TileType.smallFootballPitch.image.path
            data["team"] = RandomNameGenerator.getName()
            data["team2"] = RandomNameGenerator.getName()
            data["referee"] = RandomPersonGenerator.getName()
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
    }
}
