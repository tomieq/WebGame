//
//  ConstructionServices.swift
//  
//
//  Created by Tomasz Kucharski on 18/10/2021.
//

import Foundation


protocol ConstructionServicesDelegate {
    func notifyWalletChange(playerUUID: String)
    func notifyEveryone(_ notification: UINotification)
    func reloadMap()
}

enum ConstructionServicesError: Error {
    case formalProblem(reason: String)
    case financialTransactionProblem(reason: String)
}

class ConstructionServices {
    
    let mapManager: GameMapManager
    let centralBank: CentralBank
    let priceList: ConstructionPriceList
    let constructionDuration: ConstructionDuration
    var delegate: ConstructionServicesDelegate?
    let dataStore: DataStoreProvider
    
    init(mapManager: GameMapManager, centralBank: CentralBank, delegate: ConstructionServicesDelegate? = nil) {
        self.mapManager = mapManager
        self.dataStore = centralBank.dataStore
        self.centralBank = centralBank
        self.delegate = delegate
        self.priceList = ConstructionPriceList()
        self.constructionDuration = ConstructionDuration()
    }
    
    func roadOffer(landName: String) -> ConstructionOffer {
        let invoice = Invoice(title: "Build road on property \(landName)", netValue: self.priceList.buildRoadPrice, taxRate: self.centralBank.taxRates.investmentTax)
        let duration = self.constructionDuration.road
        return ConstructionOffer(invoice: invoice, duration: duration)
    }
    
    func residentialBuildingOffer(landName: String, storeyAmount: Int) -> ConstructionOffer {
        let invoice = Invoice(title: "Build \(storeyAmount)-storey \(landName)", netValue: self.priceList.buildResidentialBuildingPrice(storey: storeyAmount), taxRate: self.centralBank.taxRates.investmentTax)
        let duration = self.constructionDuration.residentialBuilding(storey: storeyAmount)
        return ConstructionOffer(invoice: invoice, duration: duration)
    }
    
    func buildRoad(address: MapPoint, playerUUID: String) throws {
        
        guard let land = (Storage.shared.landProperties.first { $0.address == address}) else {
            throw ConstructionServicesError.formalProblem(reason: "You can build road only on an empty land.")
        }
        guard land.ownerID == playerUUID else {
            throw ConstructionServicesError.formalProblem(reason: "You can invest only on your properties.")
        }

        guard self.mapManager.map.hasDirectAccessToRoad(address: address) else {
            throw ConstructionServicesError.formalProblem(reason: "You cannot build road here as this property has no direct access to the public road.")
        }
        let governmentID = self.dataStore.getPlayer(type: .government)?.uuid ?? ""
        let offer = self.roadOffer(landName: land.name)

        // process the transaction
        let transaction = FinancialTransaction(payerID: playerUUID, recipientID: governmentID, invoice: offer.invoice)
        if case .failure(let reason) = self.centralBank.process(transaction) {
            throw ConstructionServicesError.financialTransactionProblem(reason: reason)
        }
        
        let road = Road(land: land)
        Storage.shared.landProperties = Storage.shared.landProperties.filter { $0.address != address }
        Storage.shared.roadProperties.append(road)
        
        self.mapManager.addStreet(address: address)
        
        self.delegate?.notifyWalletChange(playerUUID: playerUUID)
        self.delegate?.reloadMap()
    }

    func buildResidentialBuilding(address: MapPoint, playerUUID: String, storeyAmount: Int) throws {
        
        guard let land = (Storage.shared.landProperties.first { $0.address == address}) else {
            throw ConstructionServicesError.formalProblem(reason: "You can build road only on an empty land.")
        }
        guard land.ownerID == playerUUID else {
            throw ConstructionServicesError.formalProblem(reason: "You can invest only on your properties.")
        }
        guard self.mapManager.map.hasDirectAccessToRoad(address: address) else {
            throw ConstructionServicesError.formalProblem(reason: "You cannot build apartment here as this property has no direct access to the public road.")
        }
        
        let offer = residentialBuildingOffer(landName: land.name, storeyAmount: storeyAmount)
        
        let building = ResidentialBuilding(land: land, storeyAmount: storeyAmount)
        building.isUnderConstruction = true
        building.constructionFinishMonth = Storage.shared.monthIteration + offer.duration
        // process the transaction
        let governmentID = self.dataStore.getPlayer(type: .government)?.uuid ?? ""
        let transaction = FinancialTransaction(payerID: playerUUID, recipientID: governmentID, invoice: offer.invoice)
        if case .failure(let reason) = self.centralBank.process(transaction) {
            throw ConstructionServicesError.financialTransactionProblem(reason: reason)
        }
        Storage.shared.landProperties = Storage.shared.landProperties.filter { $0.address != address }
        Storage.shared.residentialBuildings.append(building)
        
        let tile = GameMapTile(address: address, type: .buildingUnderConstruction(size: storeyAmount))
        self.mapManager.map.replaceTile(tile: tile)
        
        self.delegate?.notifyWalletChange(playerUUID: playerUUID)
        self.delegate?.reloadMap()
    }
}
