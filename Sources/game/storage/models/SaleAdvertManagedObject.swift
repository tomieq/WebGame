//
//  SaleAdvertManagedObject.swift
//
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation

class SaleAdvertManagedObject: Codable {
    let uuid: String
    let x: Int
    let y: Int
    var netPrice: Double

    init(_ advert: SaleAdvert) {
        self.uuid = UUID().uuidString
        self.x = advert.address.x
        self.y = advert.address.y
        self.netPrice = advert.netPrice
    }
}
