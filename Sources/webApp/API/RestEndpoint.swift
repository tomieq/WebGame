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
    case openParkingManager
    case openLandManager
    case openBuildingManager
    case openSaleOffer
    case openPropertyInfo
    case propertyWalletBalance
    case propertySellStatus
    case loadNewSaleOfferForm
    case loadEditSaleOfferForm
    case cancelSaleOffer
    case openFootballPitch
    case startInvestment
    case residentialBuildingInvestmentWizard
    
    var base: String {
        switch self {
        case .openRoadInfo:
            return "/openRoadInfo.js"
        case .openRoadManager:
            return "/openRoadManager.js"
        case .openParkingManager:
            return "/openParkingManager.js"
        case .openLandManager:
            return "/openLandManager.js"
        case .openBuildingManager:
            return "/openBuildingManager.js"
        case .openSaleOffer:
            return "/openSaleOffer.js"
        case .openPropertyInfo:
            return "/openPropertyInfo.js"
        case .propertyWalletBalance:
            return "/propertyWalletBalance.html"
        case .propertySellStatus:
            return "/propertySellStatus.html"
        case .loadNewSaleOfferForm:
            return "/loadNewSaleOfferForm.js"
        case .loadEditSaleOfferForm:
            return "/loadEditSaleOfferForm.js"
        case .cancelSaleOffer:
            return "/cancelSaleOffer.js"
        case .openFootballPitch:
            return "/openFootballPitch.js"
        case .startInvestment:
            return "/startInvestment.js"
        case .residentialBuildingInvestmentWizard:
            return "/residentialBuildingInvestmentWizard.js"
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
    func append(_ key: String, _ value: String) -> String {
        if self.contains("?") {
            return "\(self)&\(key)=\(value)"
        }
        return "\(self)?\(key)=\(value)"
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
