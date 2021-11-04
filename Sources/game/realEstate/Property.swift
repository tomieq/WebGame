//
//  Property.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

protocol Property {
    var uuid: String { get }
    var type: String { get }
    var name: String { get }
    var ownerUUID: String { get }
    var address: MapPoint { get }
    var purchaseNetValue: Double { get }
    var investmentsNetValue: Double { get }
    var isUnderConstruction: Bool { get }
    var constructionFinishMonth: Int { get }
}
