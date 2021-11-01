//
//  DebtCollector.swift
//  
//
//  Created by Tomasz Kucharski on 31/10/2021.
//

import Foundation

class DebtExecution {
    let catchMonth: Int
    let playerUUID: String
    let notificationMonth: Int
    let takePropertyMonth: Int
    
    init(catchMonth: Int, playerUUID: String) {
        self.catchMonth = catchMonth
        self.playerUUID = playerUUID
        self.notificationMonth = catchMonth + 1
        self.takePropertyMonth = catchMonth + 2
    }
}

protocol DebtCollectorDelegate {
    func notify(playerUUID: String, _ notification: UINotification)
}

class DebtCollector {
    
    let realEstateAgent: RealEstateAgent
    let dataStore: DataStoreProvider
    let time: GameTime
    var delegate: DebtCollectorDelegate?
    private var executions: [DebtExecution]
    
    init(realEstateAgent: RealEstateAgent) {
        self.realEstateAgent = realEstateAgent
        self.dataStore = realEstateAgent.dataStore
        self.time = realEstateAgent.centralBank.time
        self.executions = []
    }
    
    func executeDebts() {
        let players: [Player] = self.dataStore.getAll()
        for player in players {
            let isExecuted = self.isExecuted(playerUUID: player.uuid)
            if player.wallet < 1000, !isExecuted {
                let execution = DebtExecution(catchMonth: self.time.month, playerUUID: player.uuid)
                self.executions.append(execution)
            }
            if player.wallet >=0, isExecuted {
                self.executions.removeAll{ $0.playerUUID == player.uuid }
            }
        }
        
        for execution in self.executions {
            if execution.notificationMonth == self.time.month {
                // send notification
                let text = "You have debts. Start paying before Government Debt Collector will take your properties."
                self.delegate?.notify(playerUUID: execution.playerUUID, UINotification(text: text, level: .warning, duration: 30, icon: .moneyWarning))
            }
            if execution.takePropertyMonth == self.time.month {
                // block property and offer for sale
            }
        }
    }
    
    func isExecuted(playerUUID: String) -> Bool {
        return self.executions.contains{ $0.playerUUID == playerUUID }
    }
}
