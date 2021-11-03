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
    let startExecutionMonth: Int
    var sellPriceRatio: Double
    
    init(catchMonth: Int, playerUUID: String) {
        self.catchMonth = catchMonth
        self.playerUUID = playerUUID
        self.notificationMonth = catchMonth + 1
        self.startExecutionMonth = catchMonth + 2
        self.sellPriceRatio = 0.9
    }
}

protocol DebtCollectorDelegate {
    func notify(playerUUID: String, _ notification: UINotification)
    func notifyEveryone(_ notification: UINotification, exceptUserUUIDs: [String])
}

class DebtCollector {
    
    var montlyPropertyPriceReduction = 0.05
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
        self.updateDebtors()
    
        for execution in self.executions {
            if execution.notificationMonth == self.time.month {
                // send notification
                let text = "You have debts. Start paying off before Government Debt Collector will take the case."
                self.delegate?.notify(playerUUID: execution.playerUUID, UINotification(text: text, level: .warning, duration: 30, icon: .moneyWarning))
                if let player: Player = self.dataStore.find(uuid: execution.playerUUID) {
                    let infoToOthers = "<b>\(player.login)</b> has financial problems. He need to pay his debts otherwise his properties will be put on sale"
                    self.delegate?.notifyEveryone(UINotification(text: infoToOthers, level: .info, duration: 15, icon: .redFlag), exceptUserUUIDs: [execution.playerUUID])
                }
                continue
            }
            
            if execution.startExecutionMonth == self.time.month {
                // block property and offer for sale
                self.putPropertiesOnSale(execution, sellPriceRatio: execution.sellPriceRatio)
            }

            if self.time.month > execution.startExecutionMonth, execution.sellPriceRatio > 0.5 {
                execution.sellPriceRatio -= self.montlyPropertyPriceReduction
                self.putPropertiesOnSale(execution, sellPriceRatio: execution.sellPriceRatio)
            }
        }
    }
    
    func isExecuted(playerUUID: String) -> Bool {
        return self.executions.contains{ $0.playerUUID == playerUUID }
    }
    
    private func updateDebtors() {
        let players: [Player] = self.dataStore.getAll()
        
        for player in players {
            let isExecuted = self.isExecuted(playerUUID: player.uuid)
            if player.wallet < 1000, !isExecuted {
                let execution = DebtExecution(catchMonth: self.time.month, playerUUID: player.uuid)
                self.executions.append(execution)
            }
            if player.wallet >= 0, isExecuted {
                let registers: [PropertyRegister] = self.dataStore.get(ownerUUID: player.uuid)
                for register in registers {
                    let mutation = PropertyRegisterMutation(uuid: register.uuid, attributes: [.status(.normal)])
                    self.dataStore.update(mutation)
                    self.realEstateAgent.cancelSaleOffer(address: register.address)
                }
                self.executions.removeAll{ $0.playerUUID == player.uuid }
            }
        }
    }
    
    func putPropertiesOnSale(_ execution: DebtExecution, sellPriceRatio: Double) {
        guard let player: Player = self.dataStore.find(uuid: execution.playerUUID) else { return }
        let registers: [PropertyRegister] = self.dataStore.get(ownerUUID: execution.playerUUID)
        let properties = registers.map { register -> PropertyForDebtExecution in
            let estimatedValue = self.realEstateAgent.propertyValuer.estimateValue(register.address) ?? 1
            let salePrice = estimatedValue * sellPriceRatio
            return PropertyForDebtExecution(register: register, value: salePrice)
        }
        let debt = -1 * player.wallet
        let propertiesForSale = self.chooseProperties(properties, debt: debt)
        guard !propertiesForSale.isEmpty else { return }
        var informPlayer = false
        for property in propertiesForSale {
            
            let register = property.register
            let salePrice = property.value
            do {
                try self.realEstateAgent.registerSaleOffer(address: register.address, netValue: salePrice)
                informPlayer = true
            } catch RegisterOfferError.advertAlreadyExists {
                try? realEstateAgent.updateSaleOffer(address: register.address, netValue: salePrice)
            } catch {
                
            }
            let mutation = PropertyRegisterMutation(uuid: register.uuid, attributes: [.status(.blockedByDebtCollector)])
            self.dataStore.update(mutation)
        }
        if informPlayer {
            let text = "Debt Collector estimated your properties' value and put them on sale"
            self.delegate?.notify(playerUUID: execution.playerUUID, UINotification(text: text, level: .warning, duration: 30, icon: .moneyWarning))
        }
        
    }
    
    func chooseProperties(_ properties: [PropertyForDebtExecution], debt: Double) -> [PropertyForDebtExecution] {

        let netDebt = debt * 1.25
        let properties = properties.sorted{ $0.value < $1.value }
        guard properties.count > 1 else { return properties }
        let valueOfAllProperties = properties.map{$0.value}.reduce(0, +)
        guard valueOfAllProperties > netDebt else { return properties }

        for property in properties {
            if self.propertyValueMatches(property, debt: netDebt) {
                return [property]
            }
        }
        return properties
    }
    
    private func propertyValueMatches(_ property: PropertyForDebtExecution, debt: Double) -> Bool {
        return property.value > debt && property.value < (debt * 1.5)
    }
}

struct PropertyForDebtExecution {
    let register: PropertyRegister
    let value: Double
}
