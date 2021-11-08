//
//  ParkingBusiness.swift
//  
//
//  Created by Tomasz Kucharski on 05/11/2021.
//

import Foundation

protocol ParkingBusinessDelegate {
    func notify(playerUUID: String, _ notification: UINotification)
}

enum PayParkingDamageError: Error {
    case damageNotFound
    case alreadyPaid
    case financialProblem(FinancialTransactionError)
}

class ParkingBusiness {
    let mapManager: GameMapManager
    let dataStore: DataStoreProvider
    var delegate: ParkingBusinessDelegate?
    let time: GameTime
    var damageArchivePeriod = 12
    private var damages: [MapPoint: [ParkingDamage]] = [:]
    
    init(mapManager: GameMapManager, dataStore: DataStoreProvider, time: GameTime) {
        self.mapManager = mapManager
        self.dataStore = dataStore
        self.time = time
    }
    
    func payForDamage(address: MapPoint, damageUUID: String, centralBank: CentralBank) throws {
        guard let damage = (self.damages[address]?.first{ $0.uuid == damageUUID }) else {
            throw PayParkingDamageError.damageNotFound
        }
        guard !damage.status.isClosed else {
            throw PayParkingDamageError.alreadyPaid
        }
        guard let parking: Parking = self.dataStore.find(address: address) else {
            throw PayParkingDamageError.damageNotFound
        }
            
        var value = damage.fixPrice
        switch damage.status {
        case .partiallyCoveredByInsurance(let paidAmount):
            value -= paidAmount
        default:
            break
        }
        let invoice = Invoice(title: "Parking damage compensation, \(damage.car) - \(damage.type.name)", grossValue: value, taxRate: 0)
        let transaction = FinancialTransaction(payerUUID: parking.ownerUUID, recipientUUID: SystemPlayer.government.uuid, invoice: invoice, type: .incomeTaxFree)
        do {
            try centralBank.process(transaction)
            damage.status = .paid
        } catch let error as FinancialTransactionError {
            throw PayParkingDamageError.financialProblem(error)
        }
    }
    
    func addDamage(_ parkingDamage: ParkingDamage, address: MapPoint) {
        if self.damages[address] != nil {
            self.damages[address]?.append(parkingDamage)
        } else {
            self.damages[address] = [parkingDamage]
        }
        if let parking: Parking = self.dataStore.find(address: address) {
            let trustLevel = parking.trustLevel - parkingDamage.type.trustLoose
            self.dataStore.update(ParkingMutation(uuid: parking.uuid, attributes: [.trustLevel(trustLevel)]))
            
            if parking.insurance != .none {
                if parking.insurance.damageCoverLimit >= parkingDamage.fixPrice {
                    parkingDamage.status = .coveredByInsurance
                } else {
                    parkingDamage.status = .partiallyCoveredByInsurance(parking.insurance.damageCoverLimit)
                }
            }
        }
    }
    
    func getDamages(address: MapPoint) -> [ParkingDamage] {
        return self.damages[address] ?? []
    }
    
    func randomDamage() {
        
        let parkings: [Parking] = self.dataStore.getAll().shuffled()
        var untouchablePlayers = SystemPlayer.allCases.map{ $0.uuid }
        for parking in parkings {
            if untouchablePlayers.contains(parking.ownerUUID) {
                continue
            }
            if parking.security.effectiveneness > 0 {
                let random = Int.random(in: 0...100)
                if random < parking.security.effectiveneness {
                    continue
                }
            }
            // some time throttle
            let lastDamageTime = self.damages[parking.address]?.last?.accidentMonth ?? parking.constructionFinishMonth
            if lastDamageTime + 1 >= self.time.month {
                continue
            }
            var damageTypes = ParkingDamageType.allCases.filter{ $0.trustLoose < 0.15 }
            if let lastDamageType = self.damages[parking.address]?.last?.type {
                damageTypes.removeAll{ $0 == lastDamageType }
            }
            if let damageType = damageTypes.shuffled().first {
                let damage = ParkingDamage(type: damageType, accidentMonth: self.time.month)
                self.addDamage(damage, address: parking.address)
                let text = "Something wrong has just happen on your <b>\(parking.name)</b> located \(parking.readableAddress). Customer's \(damage.car) got damaged - \(damage.type.name)."
                self.delegate?.notify(playerUUID: parking.ownerUUID, UINotification(text: text, level: .warning, duration: 30, icon: .carDamage))
                untouchablePlayers.append(parking.ownerUUID)
            }
        }
    }
    
    func calculateCarsForParking(address: MapPoint) -> Double {
        
        let parking: Parking? = self.dataStore.find(address: address)
        let carsInTheArea = self.getCarsAroundAddress(address)
        let competitorAddresses = self.getParkingsAroundAddress(address)
        let competitors: [Parking] = competitorAddresses.compactMap{ self.dataStore.find(address: $0) }
        // competitorTrusts stores a map of competitor's shares for address (competitors' parking trusts)
        var competitorTrusts: [MapPoint: [Double]] = [:]
        
        for competitorAddress in competitorAddresses {
            let carsInCompetitorRange = self.getCarsAroundAddress(competitorAddress)
            let competitorTrust = competitors.first{ $0.address == competitorAddress }?.trustLevel ?? 1.0
            for address in carsInCompetitorRange.keys {
                if competitorTrusts[address] != nil {
                    competitorTrusts[address]?.append(competitorTrust)
                } else {
                    competitorTrusts[address] = [competitorTrust]
                }
            }
        }
        let myTrust = parking?.trustLevel ?? 1.0
        var amountOfCars: Double = 0
        for (address, numberOfCars) in carsInTheArea {
            if let trusts = competitorTrusts[address] {
                let sumOfTrust = myTrust + trusts.reduce(0, +)
                amountOfCars += numberOfCars * (myTrust / sumOfTrust)
            } else {
                amountOfCars += numberOfCars
            }
        }

        return amountOfCars
    }
    
    private func getCarsAroundAddress(_ address: MapPoint) -> [MapPoint: Double] {
        var carsPerAddress: [MapPoint: Double] = [:]
        for radius in (1...2) {
            for neighbour in self.mapManager.map.getNeighbourAddresses(to: address, radius: radius) {
                if let tileType = self.mapManager.map.getTile(address: neighbour)?.type {
                    let carsOnProperty = tileType.carsOnProperty
                    if carsOnProperty > 0 {
                        carsPerAddress[neighbour] = tileType.carsOnProperty
                    }
                }
            }
        }
        return carsPerAddress
    }
    
    func getParkingsAroundAddress(_ address: MapPoint) -> [MapPoint] {
        var parkings: [MapPoint] = []
        for radius in (1...4) {
            for parking in self.mapManager.map.getNeighbourAddresses(to: address, radius: radius) {
                if self.mapManager.map.getTile(address: parking)?.isParking() ?? false {
                    parkings.append(parking)
                }
            }
        }
        return parkings
    }
    
    func monthlyActions() {
        self.removeOldClosedDamages()
        self.applyAdvertisementChanges()
    }
    
    private func removeOldClosedDamages() {
        for address in self.damages.keys {
            self.damages[address]?.removeAll{ $0.status.isClosed && $0.accidentMonth < self.time.month - self.damageArchivePeriod  }
        }
    }
    
    private func applyAdvertisementChanges() {
        let parkings: [Parking] = self.dataStore.getAll().shuffled()
        let skippedPlayers = SystemPlayer.allCases.map{ $0.uuid }
        for parking in parkings {
            if skippedPlayers.contains(parking.ownerUUID) {
                continue
            }
            var trustLevelChange = 0.0
            if Int.random(in: 1...3) == 1 {
                trustLevelChange -= Double.random(in: 0.01...0.03)
            }
            
            if parking.advertising.monthlyTrustGain == 0, trustLevelChange == 0.0 {
                continue
            }
            let updatedTrust = parking.trustLevel + trustLevelChange + parking.advertising.monthlyTrustGain
            self.dataStore.update(ParkingMutation(uuid: parking.uuid, attributes: [.trustLevel(updatedTrust)]))
            
        }
    }
}

extension TileType {
    var carsOnProperty: Double {
        switch self {
        case .building(let size):
            return size.double
        case .cityCouncil:
            return 5
        case .school:
            return 5
        case .hospital:
            return 12
        case .footballPitch(_):
            return 5
        case .warehouse:
            return 2
        default:
            return 0
        }
    }
}
