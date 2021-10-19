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

enum ConstructionServicesError: Error, Equatable {
    case addressNotFound
    case playerIsNotPropertyOwner
    case noDirectAccessToRoad
    case financialTransactionProblem(FinancialTransactionError)
}

class ConstructionServices {
    
    let currentTime: GameTime
    let mapManager: GameMapManager
    let centralBank: CentralBank
    let priceList: ConstructionPriceList
    let constructionDuration: ConstructionDuration
    var delegate: ConstructionServicesDelegate?
    let dataStore: DataStoreProvider
    
    init(mapManager: GameMapManager, centralBank: CentralBank, time: GameTime, delegate: ConstructionServicesDelegate? = nil) {
        self.currentTime = GameTime()
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
    
    func startRoadInvestment(address: MapPoint, playerUUID: String) throws {
        
        guard let land: Land = self.dataStore.find(address: address) else {
            throw ConstructionServicesError.addressNotFound
        }
        guard land.ownerUUID == playerUUID else {
            throw ConstructionServicesError.playerIsNotPropertyOwner
        }

        guard self.mapManager.map.hasDirectAccessToRoad(address: address) else {
            throw ConstructionServicesError.noDirectAccessToRoad
        }
        let governmentID = SystemPlayer.government.uuid
        let offer = self.roadOffer(landName: land.name)

        let transaction = FinancialTransaction(payerID: playerUUID, recipientID: governmentID, invoice: offer.invoice)
        // process the transaction
        do {
             try self.centralBank.process(transaction)
        } catch let error as FinancialTransactionError {
            throw ConstructionServicesError.financialTransactionProblem(error)
        }
        
        let road = Road(land: land)
        road.isUnderConstruction = true
        road.constructionFinishMonth = self.currentTime.month + offer.duration
        
        self.dataStore.removeLand(uuid: land.uuid)
        self.dataStore.create(road)
        
        let tile = GameMapTile(address: address, type: .streetUnderConstruction)
        self.mapManager.map.replaceTile(tile: tile)

        self.delegate?.notifyWalletChange(playerUUID: playerUUID)
        self.delegate?.reloadMap()
    }

    func startResidentialBuildingInvestment(address: MapPoint, playerUUID: String, storeyAmount: Int) throws {
        
        guard let land: Land = self.dataStore.find(address: address) else {
            throw ConstructionServicesError.addressNotFound
        }
        guard land.ownerUUID == playerUUID else {
            throw ConstructionServicesError.playerIsNotPropertyOwner
        }
        guard self.mapManager.map.hasDirectAccessToRoad(address: address) else {
            throw ConstructionServicesError.noDirectAccessToRoad
        }
        
        let offer = residentialBuildingOffer(landName: land.name, storeyAmount: storeyAmount)
        
        let building = ResidentialBuilding(land: land, storeyAmount: storeyAmount)
        building.isUnderConstruction = true
        building.constructionFinishMonth = self.currentTime.month + offer.duration
        // process the transaction
        let governmentID = SystemPlayer.government.uuid
        let transaction = FinancialTransaction(payerID: playerUUID, recipientID: governmentID, invoice: offer.invoice)
        do {
             try self.centralBank.process(transaction)
        } catch let error as FinancialTransactionError {
            throw ConstructionServicesError.financialTransactionProblem(error)
        }
        self.dataStore.removeLand(uuid: land.uuid)
        Storage.shared.residentialBuildings.append(building)
        
        let tile = GameMapTile(address: address, type: .buildingUnderConstruction(size: storeyAmount))
        self.mapManager.map.replaceTile(tile: tile)
        
        self.delegate?.notifyWalletChange(playerUUID: playerUUID)
        self.delegate?.reloadMap()
    }
    
    func finishInvestments() {
        var updateMap = false
        /*
        for road in (Storage.shared.roadProperties.filter{ $0.isUnderConstruction }) {
            if road.constructionFinishMonth == self.currentTime.month {
                road.isUnderConstruction = false
                
                self.mapManager.addStreet(address: road.address)
                updateMap = true
            }
        }
        */
        for building in (Storage.shared.residentialBuildings.filter{ $0.isUnderConstruction }) {
            if building.constructionFinishMonth == self.currentTime.month {
                building.isUnderConstruction = false
                
                /*for storey in (1...building.storeyAmount) {
                    for flatNo in (1...building.numberOfFlatsPerStorey) {
                        let apartment = Apartment(building, storey: storey, flatNumber: flatNo)
                        apartment.monthlyBuildingFee = self.realEstateAgent.priceList.monthlyApartmentBuildingOwnerFee
                        Storage.shared.apartments.append(apartment)
                    }
                }
                self.realEstateAgent.recalculateFeesInTheBuilding(building)
                */
                let tile = GameMapTile(address: building.address, type: .building(size: building.storeyAmount))
                self.mapManager.map.replaceTile(tile: tile)
                updateMap = true
            }
        }
        if updateMap {
            self.delegate?.reloadMap()
        }
    }
}
