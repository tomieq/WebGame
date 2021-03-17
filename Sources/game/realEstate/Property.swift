//
//  Property.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

protocol Property {
    var owner: Player? { get }
    var address: [MapPoint] { get }
    var moneyValueWhenBought: Int? { get }
    var currentMoneyValue: Int? { get }
}
