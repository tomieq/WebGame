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
        
        Observable<Int>.interval(.seconds(300), scheduler: MainScheduler.instance).bind { [weak self] _ in
            Logger.info("GameClock", "End of the month")
            self?.endTheMonth()
            Storage.shared.monthIteration += 1
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
        self.realEstateAgent.getProperties().compactMap { $0 as? ResidentialBuilding }.forEach { building in
            self.realEstateAgent.recalculateFeesInTheBuilding(building)
        }
        
        for property in self.realEstateAgent.getProperties() {
            if let player = (Storage.shared.players.first { $0.id == property.ownerID }), player.type == .user {
                player.addIncome(property.monthlyIncome)
                player.wallet -= property.monthlyMaintenanceCost
            }
        }
        
        for session in PlayerSessionManager.shared.getActiveSessions() {
            let updateWalletEvent = GameEvent(playerSession: session, action: .updateWallet(session.player.wallet.money))
            GameEventBus.gameEvents.onNext(updateWalletEvent)
        }
        
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
