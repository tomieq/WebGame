//
//  GameEvent.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

struct GameEvent {
    let player: Player?
    let action: GameEventAction
}
enum GameEventAction {
    case userConnected
    case userDisconnected
    case tileClicked(MapPoint)
}
