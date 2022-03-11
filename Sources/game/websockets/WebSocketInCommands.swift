//
//  WebSocketInCommands.swift
//
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation

enum WebsocketCommandInType: String, Codable {
    case playerSessionID
    case tileClicked
    case vehicleFinished
}

class WebsocketInCommand: Codable {
    var command: WebsocketCommandInType?
}

class WebsocketInCommandWithPayload<T: Codable>: Codable {
    var command: WebsocketCommandInType?
    var payload: T?
}
