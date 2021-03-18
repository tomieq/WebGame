//
//  OpenWindow.swift
//  
//
//  Created by Tomasz Kucharski on 18/03/2021.
//

import Foundation

struct OpenWindow: Codable {
    let width: Int
    let height: Int
    let htmlUrl: String?
    let jsLibUrl: [String]?
    let cssUrl: [String]?
}
