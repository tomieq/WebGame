//
//  GameEvent.swift
//  
//
//  Created by Tomasz Kucharski on 16/03/2021.
//

import Foundation

struct GameEvent {
    let playerSession: PlayerSession?
    let action: GameEventAction
}

enum GameEventAction {
    case userConnected
    case userDisconnected
    case tileClicked(MapPoint)
    case vehicleTravelStarted(VehicleTravelStarted)
    case vehicleTravelFinished(VehicleTravelFinished)
    case notification(UINotification)
}
