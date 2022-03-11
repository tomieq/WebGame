//
//  Court.swift
//
//
//  Created by Tomasz Kucharski on 29/10/2021.
//

import Foundation

protocol CourtDelegate {
    func syncWalletChange(playerUUID: String)
    func notify(playerUUID: String, _ notification: UINotification)
}

class Court {
    var cases: [CourtCaseQueue]
    let centralbank: CentralBank
    var delegate: CourtDelegate?
    let time: GameTime
    let duration: CourtCaseDuration

    init(centralbank: CentralBank) {
        self.cases = []
        self.centralbank = centralbank
        self.time = centralbank.time
        self.duration = CourtCaseDuration()
    }

    func getCase(uuid: String) -> CourtCase? {
        return self.cases.first{ $0.courtCase.uuid == uuid }?.courtCase
    }

    func registerNewCase(_ courtCase: CourtCase) {
        var delay = 1
        switch courtCase.type {
        case .footballMatchBribery:
            delay = self.duration.footballMatchBriberyDuration
        case .parkingDamageLawsuite:
            delay = self.duration.parkingDamageLawsuiteDuration
        }
        let queue = CourtCaseQueue(courtCase: courtCase, trialMonth: self.time.month + delay)
        self.cases.append(queue)
    }

    func processTrials() {
        for queue in self.cases {
            if queue.trialMonth == self.time.month {
                switch queue.courtCase.type {
                case .footballMatchBribery:
                    if let footbalBribery = queue.courtCase as? FootballBriberyCase {
                        self.startFootballBriberyTrial(footbalBribery)
                    }
                case .parkingDamageLawsuite:
                    if let partkingLawsuite = queue.courtCase as? ParkingDamageLawsuite {
                        self.startParkingDamageLawsuite(partkingLawsuite)
                    }
                }
            }
        }
    }

    func startParkingDamageLawsuite(_ courtCase: ParkingDamageLawsuite) {
        if courtCase.damage.leftToPay > 0, let guilty: Player = self.centralbank.dataStore.find(uuid: courtCase.accusedUUID) {
            let fine = courtCase.damage.leftToPay * 1.8
            let damage = courtCase.damage
            let invoice = Invoice(title: "Parking damage compensation, \(damage.car) \(damage.type.name)", grossValue: fine, taxRate: 0)
            let transaction = FinancialTransaction(payerUUID: guilty.uuid, recipientUUID: SystemPlayer.government.uuid, invoice: invoice, type: .fine)
            try? self.centralbank.process(transaction, checkWalletCapacity: false)
            let verdict = "There is a verdict for lawsuite agains <b>\(guilty.login)</b> for damage of \(damage.car) - \(damage.type.name). Because you didn't have proper parking insurance and refused to pay for damages, Court sentenced \(guilty.login) to pay <b>\(fine.money)</b> as a compensation to \(damage.carOwner), the owner of the car."
            self.delegate?.notify(playerUUID: guilty.uuid, UINotification(text: verdict, level: .error, duration: 60, icon: .court))
            self.delegate?.syncWalletChange(playerUUID: guilty.uuid)
            damage.status = .paid
        }
        self.cases.removeAll{ $0.courtCase.uuid == courtCase.uuid }
    }

    func startFootballBriberyTrial(_ courtCase: FootballBriberyCase) {
        if let guilty: Player = self.centralbank.dataStore.find(uuid: courtCase.accusedUUID) {
            let fine = courtCase.illegalWin * 2
            let invoice = Invoice(title: "Bribery trial fine", grossValue: fine, taxRate: 0)
            let transaction = FinancialTransaction(payerUUID: guilty.uuid, recipientUUID: SystemPlayer.government.uuid, invoice: invoice, type: .fine)
            try? self.centralbank.process(transaction, checkWalletCapacity: false)
            let verdict = "\(guilty.login) was found guilty of bribing referee \(courtCase.bribedReferees.joined(separator: ", ")) and thus making illegal income from football bets. Court sentenced \(guilty.login) to pay <b>\(fine.money)</b> fine."
            self.delegate?.notify(playerUUID: guilty.uuid, UINotification(text: verdict, level: .error, duration: 60, icon: .court))
            self.delegate?.syncWalletChange(playerUUID: guilty.uuid)
        }
        self.cases.removeAll{ $0.courtCase.uuid == courtCase.uuid }
    }
}

enum CourtCaseType {
    case footballMatchBribery
    case parkingDamageLawsuite
}

protocol CourtCase {
    var uuid: String { get }
    var type: CourtCaseType { get }
    var accusedUUID: String { get }
}

struct CourtCaseQueue {
    let courtCase: CourtCase
    let trialMonth: Int
}

struct FootballBriberyCase: CourtCase {
    let uuid: String
    let type: CourtCaseType
    let accusedUUID: String
    let illegalWin: Double
    let bribedReferees: [String]

    init(accusedUUID: String, illegalWin: Double, bribedReferees: [String]) {
        self.uuid = UUID().uuidString
        self.type = .footballMatchBribery
        self.accusedUUID = accusedUUID
        self.illegalWin = illegalWin
        self.bribedReferees = bribedReferees
    }
}

struct ParkingDamageLawsuite: CourtCase {
    let uuid: String
    let type: CourtCaseType
    let accusedUUID: String
    let damage: ParkingDamage

    init(accusedUUID: String, damage: ParkingDamage) {
        self.uuid = damage.uuid
        self.type = .parkingDamageLawsuite
        self.accusedUUID = accusedUUID
        self.damage = damage
    }
}

class CourtCaseDuration {
    var footballMatchBriberyDuration: Int = 2
    var parkingDamageLawsuiteDuration: Int = 2
}
