//
//  GameClock.swift
//  
//
//  Created by Tomasz Kucharski on 25/03/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol GameClockDelegate {
    func nextMonth()
    func syncTime()
}

class GameClock {
    let realEstateAgent: RealEstateAgent
    let time: GameTime
    let secondsPerMonth: Int
    private var secondsCounter: Int
    private let dataStore: DataStoreProvider
    var delegate: GameClockDelegate?
    private let disposeBag = DisposeBag()
    
    var secondsLeft: Int {
        self.secondsPerMonth - self.secondsCounter
    }
    
    init(realEstateAgent: RealEstateAgent, time: GameTime, secondsPerMonth: Int) {
        self.time = time
        self.realEstateAgent = realEstateAgent
        self.dataStore = realEstateAgent.dataStore
        self.delegate = nil
        self.secondsPerMonth = secondsPerMonth
        self.secondsCounter = 0
        
        Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).bind { [weak self] number in
            guard let `self` = self else { return }
            self.secondsCounter += 1
            
            if self.secondsCounter == self.secondsPerMonth {
                self.secondsCounter = 0
                
                Logger.info("GameClock", "End of the month")
                self.time.nextMonth()
                self.delegate?.nextMonth()
            } else if self.secondsCounter % 60 == 0 {
                self.delegate?.syncTime()
            }
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
        /*
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
        
         */

    }
    
    private func applyWalletChanges(property: Property) {
        /*
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
         */
    }
    
    private func pruneBankTransactionArchive() {
        //let currentMonth = Storage.shared.monthIteration
        //let borderMonth = currentMonth - 12
        //Storage.shared.transactionArchive = Storage.shared.transactionArchive.filter { $0.month > borderMonth }
    }
}
