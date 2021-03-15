//
//  File.swift
//  
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation

enum BackendCommandType: String, Codable {
    case tileClicked
}

class BackendAnonymouseCommand: Codable {
    var command: BackendCommandType?
}

enum FrontEndCommandType: String, Codable {
    case startVehicle
}

class BackendCommand<T: Codable>: Codable {
    var command: BackendCommandType?
    var data: T?
}

class FrontEndCommand<T: Codable>: Codable {
    var command: FrontEndCommandType?
    let data: T

    init(_ data: T) {
        self.data = data
    }
}

class StartVehicleDto: Codable {
    var id: String?
    var type: String?
    var speed: Int?
    var points: [MapPoint]?
    
    init() {
        self.id = UUID().uuidString
        self.type = "car1"
        self.speed = 12
        self.points = []
    }
}
