//
//  RestEndpoint.swift
//  
//
//  Created by Tomasz Kucharski on 25/10/2021.
//

import Foundation
import Swifter

enum RestEndpoint {
    case openRoadInfo
    case openRoadManager
    case openLandManager
    case openSaleOffer
    case openPropertyInfo
    case openPublishSaleOffer
    case openEditSaleOffer
    case cancelSaleOffer
    
    var base: String {
        switch self {
        case .openRoadInfo:
            return "/openRoadInfo.js"
        case .openRoadManager:
            return "/openRoadManager.js"
        case .openLandManager:
            return "/openLandManager.js"
        case .openSaleOffer:
            return "/openSaleOffer.js"
        case .openPropertyInfo:
            return "/openPropertyInfo.js"
        case .openPublishSaleOffer:
            return "/openPublishSaleOffer.js"
        case .openEditSaleOffer:
            return "/openEditSaleOffer.js"
        case .cancelSaleOffer:
            return "/cancelSaleOffer.js"
        }
    }
}

extension RestEndpoint {
    func append(_ address: MapPoint) -> String {
        let text = self.base
        if text.contains("?") {
            return "\(text)&\(address.asQueryParams)"
        }
        return "\(text)?\(address.asQueryParams)"
    }
}

extension String {
    func append(_ address: MapPoint) -> String {
        if self.contains("?") {
            return "\(self)&\(address.asQueryParams)"
        }
        return "\(self)?\(address.asQueryParams)"
    }
}

extension HttpServer.MethodRoute {
    subscript(path: RestEndpoint) -> ((HttpRequest, HttpResponseHeaders) -> HttpResponse)? {
        set {
            router.register(method, path: path.base, handler: newValue)
        }
        get { return nil }
    }
}