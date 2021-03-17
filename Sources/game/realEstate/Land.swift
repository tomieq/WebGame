//
//  Land.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

class Land: Property, Codable {
    
    var owner: Player?
    var address: [MapPoint]
    var moneyValueWhenBought: Int?
    var currentMoneyValue: Int?
    
    init(address: MapPoint) {
        self.address = [address]
    }


}
