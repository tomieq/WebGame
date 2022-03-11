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
    var executedProperties: [ExecutedProperty]

    init(catchMonth: Int, playerUUID: String, startExecutionDelay: Int) {
        self.catchMonth = catchMonth
        self.playerUUID = playerUUID
        self.notificationMonth = catchMonth + 1
        self.startExecutionMonth = catchMonth + 1 + startExecutionDelay
        self.executedProperties = []
    }
}

class ExecutedProperty {
    let register: PropertyRegister
    var nextSellPriceRatio: Double

    init(register: PropertyRegister, nextSellPriceRatio: Double) {
        self.register = register
        self.nextSellPriceRatio = nextSellPriceRatio
    }
}

protocol DebtCollectorDelegate {
    func notify(playerUUID: String, _ notification: UINotification)
    func notifyEveryone(_ notification: UINotification, exceptUserUUIDs: [String])
}

class DebtCollectorParams {
    var montlyPropertyPriceReduction = 0.05
    var initialPropertyValueRatio = 1.0
    var startExecutionDelay: Int = 1
}

class DebtCollector {
    let params: DebtCollectorParams
    let realEstateAgent: RealEstateAgent
    let dataStore: DataStoreProvider
    let time: GameTime
    var delegate: DebtCollectorDelegate?
    private var executions: [DebtExecution]

    init(realEstateAgent: RealEstateAgent) {
        self.params = DebtCollectorParams()
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
            }

            if self.time.month >= execution.startExecutionMonth {
                self.putPropertiesOnSale(execution)
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
            if player.wallet < 0, !isExecuted {
                self.addDebtor(player)
            }
            if player.wallet >= 0, isExecuted {
                self.stopExecutions(playerUUID: player.uuid)
            }
        }
    }

    private func addDebtor(_ player: Player) {
        let execution = DebtExecution(catchMonth: self.time.month, playerUUID: player.uuid, startExecutionDelay: self.params.startExecutionDelay)
        self.executions.append(execution)

        let registers: [PropertyRegister] = self.dataStore.get(ownerUUID: player.uuid)
        for register in registers {
            // get rid of all costs
            switch register.type {
            case .parking:
                self.dataStore.update(ParkingMutation(uuid: register.uuid, attributes: [.insurance(.none), .security(.none), .advertising(.none)]))
            default:
                break
            }
        }
    }

    private func stopExecutions(playerUUID: String) {
        let registers: [PropertyRegister] = self.dataStore.get(ownerUUID: playerUUID)
        for register in registers {
            let mutation = PropertyRegisterMutation(uuid: register.uuid, attributes: [.status(.normal)])
            self.dataStore.update(mutation)
            self.realEstateAgent.cancelSaleOffer(address: register.address)
        }
        self.executions.removeAll{ $0.playerUUID == playerUUID }
        let text = "Debt Collector finished work with you. Now you have clean financial situation"
        self.delegate?.notify(playerUUID: playerUUID, UINotification(text: text, level: .success, duration: 15, icon: .moneyWarning))
    }

    func putPropertiesOnSale(_ execution: DebtExecution) {
        guard let player: Player = self.dataStore.find(uuid: execution.playerUUID) else { return }
        let allRegisters: [PropertyRegister] = self.dataStore.get(ownerUUID: execution.playerUUID)

        let allProperties = allRegisters.map { register -> PropertyForDebtExecution in
            let estimatedValue = self.realEstateAgent.propertyValuer.estimateValue(register.address) ?? 1
            let sellPriceRatio = execution.executedProperties.first{ $0.register == register }?.nextSellPriceRatio ?? self.params.initialPropertyValueRatio
            let salePrice = estimatedValue * sellPriceRatio
            return PropertyForDebtExecution(register: register, value: salePrice)
        }
        let registersOnSale = execution.executedProperties.map{ $0.register }
        let propertiesOnSale = allProperties.filter{ registersOnSale.contains($0.register) }

        let saleTotalValue = propertiesOnSale.map{ $0.value }.reduce(0, +)

        let debt = -1 * player.wallet
        guard debt > 0 else {
            self.stopExecutions(playerUUID: execution.playerUUID)
            return
        }
        let uncoveredDebt = debt - saleTotalValue
        var propertiesForSale = propertiesOnSale
        if uncoveredDebt > 0 {
            let propertiesNotForSale = allProperties.filter{ !registersOnSale.contains($0.register) }
            propertiesForSale.append(contentsOf: self.chooseProperties(propertiesNotForSale, debt: uncoveredDebt))
        }
        guard !propertiesForSale.isEmpty else { return }
        Logger.info("DebtCollector", "Player \(player.login) with \(debt.money) debt: Put on sale properties \(propertiesForSale.map{ $0.register.address.description }.joined(separator: ", "))")
        var informPlayer = false
        for property in propertiesForSale {
            let register = property.register
            let salePrice = property.value

            do {
                if let executedProperty = (execution.executedProperties.first{ $0.register == register }) {
                    if executedProperty.nextSellPriceRatio > 0.5 {
                        executedProperty.nextSellPriceRatio -= self.params.montlyPropertyPriceReduction
                    }
                    try self.realEstateAgent.updateSaleOffer(address: register.address, netValue: salePrice)
                } else {
                    let nextSellPriceRatio = self.params.initialPropertyValueRatio - self.params.montlyPropertyPriceReduction
                    execution.executedProperties.append(ExecutedProperty(register: register, nextSellPriceRatio: nextSellPriceRatio))

                    try self.realEstateAgent.registerSaleOffer(address: register.address, netValue: salePrice)
                    informPlayer = true

                    let mutation = PropertyRegisterMutation(uuid: register.uuid, attributes: [.status(.blockedByDebtCollector)])
                    self.dataStore.update(mutation)
                }

            } catch {
                Logger.error("DebtCollector", "Error: \(error)")
            }
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
        let valueOfAllProperties = properties.map{ $0.value }.reduce(0, +)
        guard valueOfAllProperties > netDebt else { return properties }

        for property in properties {
            if self.propertyValueMatches(property, debt: netDebt) {
                return [property]
            }
        }
        var chosenProperties: [PropertyForDebtExecution] = []
        var leftDebtToCover = netDebt
        for property in properties {
            chosenProperties.append(property)
            leftDebtToCover -= property.value
            if leftDebtToCover < 0 {
                return chosenProperties
            }
        }
        return chosenProperties
    }

    private func propertyValueMatches(_ property: PropertyForDebtExecution, debt: Double) -> Bool {
        return property.value > debt && property.value < (debt * 1.5)
    }
}

struct PropertyForDebtExecution: Equatable {
    let register: PropertyRegister
    let value: Double

    static func == (lhs: PropertyForDebtExecution, rhs: PropertyForDebtExecution) -> Bool {
        lhs.register.uuid == rhs.register.uuid
    }
}
