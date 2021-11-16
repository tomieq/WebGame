//
//  ConstructionServicesAPI.swift
//  
//
//  Created by Tomasz Kucharski on 16/11/2021.
//

import Foundation

class ConstructionServicesAPI: RestAPI {
    
    override func setupEndpoints() {
        
        // MARK: openLandManager
        server.GET[.startInvestment] = { request, _ in
            request.disableKeepAlive = true
            let code = JSResponse()
            guard let windowIndex = request.queryParam("windowIndex") else {
                return self.jsError("Invalid request! Missing window context.")
            }
            guard let address = request.mapPoint else {
                return self.jsError("Invalid request! Missing address.")
            }
            guard let playerSessionID = request.queryParam("playerSessionID"),
                let session = PlayerSessionManager.shared.getPlayerSession(playerSessionID: playerSessionID) else {
                    code.add(.closeWindow(windowIndex))
                    code.add(.showError(txt: "Invalid request! Missing session ID.", duration: 10))
                    return code.response
            }
            guard let investmentType = request.queryParam("type") else {
                return self.jsError("Invalid request! Missing investmentType.")
            }
            
            do {
                switch investmentType {
                case "road":
                    try self.gameEngine.constructionServices.startRoadInvestment(address: address, playerUUID: session.playerUUID)
                case "parking":
                    try self.gameEngine.constructionServices.startParkingInvestment(address: address, playerUUID: session.playerUUID)
                default:
                    return self.jsError("Invalid request! Invalid investmentType \(investmentType).")
                }
                
            } catch ConstructionServicesError.addressNotFound {
                return self.jsError("You can build only on an empty land.")
            } catch ConstructionServicesError.playerIsNotPropertyOwner {
                return self.jsError("You can invest only on your properties.")
            } catch ConstructionServicesError.noDirectAccessToRoad {
                return self.jsError("You cannot build here as this property has no direct access to the public road.")
            } catch ConstructionServicesError.financialTransactionProblem(let reason) {
                return self.jsError(reason.description)
            } catch {
                return self.jsError("Unexpected error [\(request.address ?? "")]")
            }
            code.add(.closeWindow(windowIndex))
            return code.response
        }
    }
    
}
