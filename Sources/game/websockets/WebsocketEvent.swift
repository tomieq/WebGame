//
//  WebsocketEvent.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

struct WebsocketEvent {
    let playerSesssionID: String
    let eventType: WebsocketEventType
}

enum WebsocketEventType {
    case userConnected
    case userDisconnected
    case tileClicked(MapPoint)
}
