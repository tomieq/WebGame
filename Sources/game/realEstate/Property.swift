//
//  Property.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

protocol Property {
    var id: String { get }
    var type: String { get }
    var name: String { get }
    var ownerID: String? { set get }
    var address: MapPoint { get }
    var purchaseNetValue: Double? { set get }
    var investmentsNetValue: Double { set get }
    var monthlyMaintenanceCost: Double { set get }
    var monthlyIncome: Double { set get }
}
