//
//  ConstructionServices.swift
//  
//
//  Created by Tomasz Kucharski on 18/10/2021.
//

import Foundation


protocol ConstructionServicesDelegate {
    func syncWalletChange(playerUUID: String)
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
    
    let time: GameTime
    let mapManager: GameMapManager
    let centralBank: CentralBank
    let priceList: ConstructionPriceList
    let constructionDuration: ConstructionDuration
    var delegate: ConstructionServicesDelegate?
    let dataStore: DataStoreProvider
    
    init(mapManager: GameMapManager, centralBank: CentralBank, time: GameTime, delegate: ConstructionServicesDelegate? = nil) {
        self.time = time
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

        let transaction = FinancialTransaction(payerUUID: playerUUID, recipientUUID: governmentID, invoice: offer.invoice, type: .investments)
        // process the transaction
        do {
             try self.centralBank.process(transaction)
        } catch let error as FinancialTransactionError {
            throw ConstructionServicesError.financialTransactionProblem(error)
        }

        self.dataStore.removeLand(uuid: land.uuid)

        let constructionFinishMonth = self.time.month + offer.duration
        let investmentsNetValue = offer.invoice.netValue
        let road = Road(land: land, constructionFinishMonth: constructionFinishMonth, investmentsNetValue: investmentsNetValue)
        self.dataStore.create(road)
        
        let tile = GameMapTile(address: address, type: .streetUnderConstruction)
        self.mapManager.map.replaceTile(tile: tile)

        self.delegate?.syncWalletChange(playerUUID: playerUUID)
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
        
        let constructionFinishMonth = self.time.month + offer.duration
        let investmentsNetValue = offer.invoice.netValue
        let building = ResidentialBuilding(land: land, storeyAmount: storeyAmount, constructionFinishMonth: constructionFinishMonth, investmentsNetValue: investmentsNetValue)
        self.dataStore.create(building)
        // process the transaction
        let governmentID = SystemPlayer.government.uuid
        let transaction = FinancialTransaction(payerUUID: playerUUID, recipientUUID: governmentID, invoice: offer.invoice, type: .investments)
        do {
             try self.centralBank.process(transaction)
        } catch let error as FinancialTransactionError {
            throw ConstructionServicesError.financialTransactionProblem(error)
        }
        self.dataStore.removeLand(uuid: land.uuid)
        self.dataStore.create(building)
        
        let tile = GameMapTile(address: address, type: .buildingUnderConstruction(size: storeyAmount))
        self.mapManager.map.replaceTile(tile: tile)
        
        self.delegate?.syncWalletChange(playerUUID: playerUUID)
        self.delegate?.reloadMap()
    }
    
    func finishInvestments() {
        Logger.info("ConstructionServices", "Finish all constructions for \(self.time.month)")
        var updateMap = false
        
        let roads: [Road] = self.dataStore.getUnderConstruction()
        for road in roads {
            if road.constructionFinishMonth == self.time.month {
                let mutation = RoadMutation(uuid: road.uuid, attributes: [.isUnderConstruction(false)])
                self.dataStore.update(mutation)
                
                self.mapManager.addStreet(address: road.address)
                updateMap = true
            }
        }
        
        let buildings: [ResidentialBuilding] = self.dataStore.getUnderConstruction()
        for building in buildings {
            if building.constructionFinishMonth == self.time.month {
                
                self.dataStore.update(ResidentialBuildingMutation(uuid: building.uuid, attributes: [.isUnderConstruction(false)]))
                
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
