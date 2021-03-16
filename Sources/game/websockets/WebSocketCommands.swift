//
//  WebSocketCommands.swift
//  
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation


enum WebsocketCommandInType: String, Codable {
    case playerSessionID
    case tileClicked
}

class WebsocketInCommand: Codable {
    var command: WebsocketCommandInType?
}

class WebsocketInCommandWithPayload<T: Codable>: Codable {
    var command: WebsocketCommandInType?
    var payload: T?
}


enum WebsocketCommandOutType: String, Codable {
    case startVehicle
}

class WebsocketOutCommand<T: Codable>: Codable {

    var command: WebsocketCommandOutType
    let payload: T

    init(_ command: WebsocketCommandOutType, _ payload: T) {
        self.command = command
        self.payload = payload
    }
}
