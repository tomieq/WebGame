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
    var ownerUUID: String? { set get }
    var address: MapPoint { get }
    var purchaseNetValue: Double? { set get }
    var investmentsNetValue: Double { set get }
    var isUnderConstruction: Bool { set get }
    var constructionFinishMonth: Int? { set get }
    var accountantID: String? { set get }
}
