//
//  GameClock.swift
//  
//
//  Created by Tomasz Kucharski on 25/03/2021.
//

import Foundation
import RxSwift
import RxCocoa

class GameClock {
    let realEstateAgent: RealEstateAgent
    let time: GameTime
    private let dataStore: DataStoreProvider
    private let disposeBag = DisposeBag()
    
    init(realEstateAgent: RealEstateAgent, time: GameTime) {
        self.time = GameTime()
        self.realEstateAgent = realEstateAgent
        self.dataStore = realEstateAgent.dataStore
        
        Observable<Int>.interval(.seconds(33), scheduler: MainScheduler.instance).bind { [weak self] _ in
            Logger.info("GameClock", "End of the month")
            self?.endTheMonth()
            self?.pruneBankTransactionArchive()
            Storage.shared.monthIteration += 1
            
            
            let now = GameDate(monthIteration: Storage.shared.monthIteration)
            self?.time.month = now.monthIteration
            let updateDateEvent = GameEvent(playerSession: nil, action: .updateGameDate(now.text))
            GameEventBus.gameEvents.onNext(updateDateEvent)
        }.disposed(by: self.disposeBag)
    }
    
    private func endTheMonth() {
        let apartments = Storage.shared.apartments
        
        for apartmnent in apartments {
            if apartmnent.isRented, Int.random(in: 1...6) == 1 {
                apartmnent.condition -= Bool.random() ? 0.01 : 0.02
                
                if apartmnent.condition < 40, Int.random(in: 1...8) == 1 {
                    // TODO message to the player that tenants moved out
                    apartmnent.isRented = false
                }
            }
        }
        
        for land in Storage.shared.landProperties {
            self.applyWalletChanges(property: land)
        }
        
        for road in Storage.shared.roadProperties {
            self.applyWalletChanges(property: road)
        }
        
        for building in Storage.shared.residentialBuildings {
            if !building.isUnderConstruction {
                self.realEstateAgent.recalculateFeesInTheBuilding(building)
                self.applyWalletChanges(property: building)
            }
        }
        
        for session in PlayerSessionManager.shared.getActiveSessions() {
            if let player = self.dataStore.find(uuid: session.playerUUID) {
                let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(player.wallet.money))
                GameEventBus.gameEvents.onNext(updateWalletEvent)
            }
        }
        
    }
    
    private func applyWalletChanges(property: Property) {
        if let ownerID = property.ownerID, let owner = self.dataStore.find(uuid: ownerID), owner.type == .user,
            let government = self.dataStore.getPlayer(type: .government) {
            
            let incomeInvoice = Invoice(title: "Monthly income from \(property.name)", netValue: property.monthlyIncome, taxRate: self.realEstateAgent.centralBank.taxRates.incomeTax)
            let incomeTransaction = FinancialTransaction(payerID: government.uuid, recipientID: owner.uuid, invoice: incomeInvoice)
            if property.monthlyIncome > 0 {
                self.realEstateAgent.centralBank.process(incomeTransaction)
            }
            
            let costsInvoice = Invoice(title: "Monthly costs in \(property.name)", netValue: property.monthlyMaintenanceCost, taxRate: self.realEstateAgent.centralBank.taxRates.monthlyBuildingCostsTax)
            let costsTransaction = FinancialTransaction(payerID: owner.uuid, recipientID: government.uuid, invoice: costsInvoice)
            
            if property.monthlyMaintenanceCost > 0 {
                self.realEstateAgent.centralBank.process(costsTransaction)
            }
            if property.monthlyIncome > 0, property.accountantID != nil {
                self.realEstateAgent.centralBank.refundIncomeTax(receiverID: ownerID, transaction: incomeTransaction, costs: property.monthlyMaintenanceCost)
            }
        }
    }
    
    private func pruneBankTransactionArchive() {
        //let currentMonth = Storage.shared.monthIteration
        //let borderMonth = currentMonth - 12
        //Storage.shared.transactionArchive = Storage.shared.transactionArchive.filter { $0.month > borderMonth }
    }
}

struct GameDate {
    let monthIteration: Int
    let month: Int
    let year: Int
    
    var text: String {
        return "\(month)/\(year)"
    }
    
    init(monthIteration: Int) {
        self.monthIteration = monthIteration
        self.month = monthIteration % 12 + 1
        self.year = 2000 + (monthIteration - self.month + 1)/12
    }
}
