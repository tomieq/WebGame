//
//  GameEvent.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

struct GameEvent {
    let player: Player?
}
enum GameEventAction {
    case tileClicked(MapPoint)
}
