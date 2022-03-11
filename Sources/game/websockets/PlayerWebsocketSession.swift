//
//  PlayerWebsocketSession.swift
//
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation
import Swifter

class PlayerWebsocketSession {
    var playerSession: PlayerSession?
    let websocketSession: WebSocketSession

    init(websocketSession: WebSocketSession) {
        self.websocketSession = websocketSession
    }
}
