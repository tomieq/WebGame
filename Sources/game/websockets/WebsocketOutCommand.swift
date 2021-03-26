//
//  WebsocketOutCommand.swift
//  
//
//  Created by Tomasz Kucharski on 17/03/2021.
//

import Foundation

enum WebsocketCommandOutType: String, Codable {
    case startVehicle
    case reloadMap
    case highlightArea
    case openWindow
    case notification
    case updateWallet
    case updateGameDate
}

class WebsocketOutCommand<T: Codable>: Codable {

    var command: WebsocketCommandOutType
    let payload: T

    init(_ command: WebsocketCommandOutType, _ payload: T) {
        self.command = command
        self.payload = payload
    }
}
