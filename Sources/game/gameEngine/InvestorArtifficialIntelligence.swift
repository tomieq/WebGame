//
//  InvestorArtifficialIntelligence.swift
//  
//
//  Created by Tomasz Kucharski on 22/10/2021.
//

import Foundation

class InvestorArtifficialIntelligenceParams {
    var instantPurchaseToEstimatedValueFactor: Double = 0.85
}

class InvestorArtifficialIntelligence {
    let agent: RealEstateAgent
    let params: InvestorArtifficialIntelligenceParams
    
    init(agent: RealEstateAgent) {
        self.agent = agent
        self.params = InvestorArtifficialIntelligenceParams()
    }
    
    func purchaseBargains() {
        let offers = agent.getAllSaleOffers(buyerUUID: SystemPlayer.government.uuid)
        for offer in offers {
            if let estimatedValue = self.agent.propertyValuer.estimateValue(offer.property.address) {
                let acceptablePrice = estimatedValue * self.params.instantPurchaseToEstimatedValueFactor
                if  offer.saleInvoice.netValue <= acceptablePrice {
                    try? self.agent.buyProperty(address: offer.property.address, buyerUUID: SystemPlayer.government.uuid)
                }
            }
        }
    }
}

