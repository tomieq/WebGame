//
//  Property.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

protocol Property {
    var type: String { get }
    var name: String { get }
    var ownerID: String? { set get }
    var address: MapPoint { get }
    var transactionNetValue: Double? { set get }
    var monthlyMaintenanceCost: Double { set get }
    var monthlyIncome: Double { set get }
}

protocol ResidentialProperty: Property {
    var personMaxCapacity: UInt { get }
    var personCurrentCapacity: UInt { get }
}

protocol BusinessProperty: Property {
    var bissnessRangeRadius: UInt { get }
}
