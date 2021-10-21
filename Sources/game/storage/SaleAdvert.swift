//
//  SaleAdvert.swift
//  
//
//  Created by Tomasz Kucharski on 21/10/2021.
//

import Foundation


struct SaleAdvert {
    let uuid: String
    let address: MapPoint
    let netPrice: Double
    
    init(address: MapPoint, netPrice: Double) {
        self.uuid = ""
        self.address = address
        self.netPrice = netPrice
    }
    
    init(_ managedObject: SaleAdvertManagedObject) {
        self.uuid = managedObject.uuid
        self.netPrice = managedObject.netPrice
        self.address = MapPoint(x: managedObject.x, y: managedObject.y)
    }
}
