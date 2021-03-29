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
    private let disposeBag = DisposeBag()
    
    init(realEstateAgent: RealEstateAgent) {
        self.realEstateAgent = realEstateAgent
        
        Observable<Int>.interval(.seconds(33), scheduler: MainScheduler.instance).bind { [weak self] _ in
            Logger.info("GameClock", "End of the month")
            self?.endTheMonth()
            self?.pruneBankTransactionArchive()
            Storage.shared.monthIteration += 1
            
            let now = GameDate(monthIteration: Storage.shared.monthIteration)
            let updateDateEvent = GameEvent(playerSession: nil, action: .updateGameDate("\(now.month)/\(now.year)"))
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
            self.realEstateAgent.recalculateFeesInTheBuilding(building)
            self.applyWalletChanges(property: building)
        }
        
        for session in PlayerSessionManager.shared.getActiveSessions() {
            let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
            GameEventBus.gameEvents.onNext(updateWalletEvent)
        }
        
    }
    
    private func applyWalletChanges(property: Property) {
        if let ownerID = property.ownerID, let owner = Storage.shared.getPlayer(id: ownerID), owner.type == .user,
            let government = Storage.shared.getPlayer(id: SystemPlayerID.government.rawValue) {
            
            let incomeInvoice = Invoice(title: "Monthly income from \(property.name)", netValue: property.monthlyIncome, taxPercent: TaxRates.incomeTax)
            let incomeTransaction = FinancialTransaction(payerID: government.id, recipientID: owner.id, invoice: incomeInvoice)
            CentralBank.shared.process(incomeTransaction)
            
            let costsInvoice = Invoice(title: "Monthly costs in \(property.name)", netValue: property.monthlyMaintenanceCost, taxPercent: TaxRates.monthlyBuildingCostsTax)
            let costsTransaction = FinancialTransaction(payerID: owner.id, recipientID: government.id, invoice: costsInvoice)
            CentralBank.shared.process(costsTransaction)
        }
    }
    
    private func pruneBankTransactionArchive() {
        let currentMonth = Storage.shared.monthIteration
        let borderMonth = currentMonth - 12
        Storage.shared.transactionArchive = Storage.shared.transactionArchive.filter { $0.monthIteration > borderMonth }
    }
}

struct GameDate {
    let monthIteration: Int
    let month: Int
    let year: Int
    
    init(monthIteration: Int) {
        self.monthIteration = monthIteration
        self.month = monthIteration % 12 + 1
        self.year = 2000 + (monthIteration - self.month + 1)/12
    }
}
