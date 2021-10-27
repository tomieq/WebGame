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
        self.server.GET[.footballPitchInfo] = { request, _ in
            request.disableKeepAlive = true
            guard let windowIndex = request.queryParam("windowIndex") else {
                return JSCode.showError(txt: "Invalid request! Missing window context.", duration: 10).response
            }
            guard let address = request.mapPoint else {
                return JSCode.showError(txt: "Invalid request! Missing address.", duration: 10).response
            }
            let js = JSResponse()
            js.add(.loadHtml(windowIndex, htmlPath: "/footballPitchInfo.html?&\(address.asQueryParams)"))
            js.add(.setWindowTitle(windowIndex, title: "Football pitch"))
            js.add(.disableWindowResizing(windowIndex))
            return js.response
        }
        
        // MARK: roadInfo.html
        self.server.GET["/footballPitchInfo.html"] = { request, _ in
            request.disableKeepAlive = true

            let template = Template(raw: ResourceCache.shared.getAppResource("templates/footballPitchInfo.html"))
            var data = [String:String]()
            data["tileUrl"] = TileType.smallFootballPitch.image.path
            template.assign(variables: data)
            return .ok(.html(template.output()))
        }
    }
}
