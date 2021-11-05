//
//  PropertySaleStatusView.swift
//  
//
//  Created by Tomasz Kucharski on 05/11/2021.
//

import Foundation

class PropertySaleStatusView {
    private var data: [String: String] = [:]
    private var saleOffer: SaleOffer?
    private var property: Property
    
    init(property: Property) {
        self.property = property
        self.data["purchasePrice"] = property.purchaseNetValue.rounded(toPlaces: 0).money
        self.data["investmentsValue"] = property.investmentsNetValue.money
    }
    
    @discardableResult
    func setOffer(_ saleOffer: SaleOffer?) -> PropertySaleStatusView {
        self.saleOffer = saleOffer
        return self
    }
    
    func output(windowIndex: String) -> String {
        let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManager/saleStatusView.html"))
        template.assign(variables: self.data)
        if let offer = self.saleOffer {
            var data = [String:String]()
            data["price"] = offer.saleInvoice.netValue.money
            data["cancelOfferJS"] = JSCode.runScripts(windowIndex, paths: [RestEndpoint.cancelSaleOffer.append(self.property.address)]).js
            data["editOfferJS"] = JSCode.runScripts(windowIndex, paths: [RestEndpoint.loadEditSaleOfferForm.append(self.property.address)]).js
            template.assign(variables: data, inNest: "forSale")
        } else {
            var data = [String:String]()
            data["publishOfferJS"] = JSCode.runScripts(windowIndex, paths: [RestEndpoint.loadNewSaleOfferForm.append(property.address)]).js
            template.assign(variables: data, inNest: "notForSale")
        }
        return template.output()
        
    }
}
