//
//  WebsocketOutCommand.swift
//  
//
//  Created by Tomasz Kucharski on 17/03/2021.
//

import Foundation

enum WebsocketOutCommand {
    case startVehicle(VehicleTravelStarted)
    case reloadMap
    case highlightArea(HighlightArea)
    case openWindow(OpenWindow)
    case runScript(String)
    case notification(UINotification)
    case updateWallet(String)
    case updateGameDate(UIGameDate)
    
    var type: String {
        switch self {
        case .startVehicle:
            return "startVehicle"
        case .reloadMap:
            return "reloadMap"
        case .highlightArea:
            return "highlightArea"
        case .openWindow:
            return "openWindow"
        case .notification(_):
            return "notification"
        case .updateWallet:
            return "updateWallet"
        case .updateGameDate:
            return "updateGameDate"
        case .runScript:
            return "runScript"
        }
    }
    
    var payload: Codable {
        switch self {
            
        case .startVehicle(let payload):
            return payload
        case .reloadMap:
            return ""
        case .highlightArea(let payload):
            return payload
        case .openWindow(let payload):
            return payload
        case .notification(let payload):
            return payload
        case .updateWallet(let payload):
            return payload
        case .updateGameDate(let payload):
            return payload
        case .runScript(let payload):
            return payload
        }
    }
    
    var json: String {
        return "{ \"command\": \"\(self.type)\", \"payload\": \(self.payload.toJSONString() ?? "{}") }"
    }
}
