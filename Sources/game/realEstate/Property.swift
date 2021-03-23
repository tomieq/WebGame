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
    var address: [MapPoint] { get }
    var moneyValueWhenBought: Double? { set get }
    var currentMoneyValue: Double? { set get }
    var mapTiles: [GameMapTile] { get }
}

protocol ResidentialProperty: Property {
    var personMaxCapacity: UInt { get }
    var personCurrentCapacity: UInt { get }
}

protocol BusinessProperty: Property {
    var bissnessRangeRadius: UInt { get }
}
