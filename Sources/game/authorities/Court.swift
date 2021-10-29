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
    var cases: [CourtCase]
    let centralbank: CentralBank
    var delegate: CourtDelegate?
    
    init(centralbank: CentralBank) {
        self.cases = []
        self.centralbank = centralbank
    }
    
    func registerNewCase(_ courtCase: CourtCase) {
        self.cases.append(courtCase)
    }
    
    func nextMonth() {
        for trial in self.cases {
            switch trial.type {
            case .footballMatchBribery:
                if let footbalBribery = trial as? FootballBriberyCase {
                    self.startFootballBriberyTrial(footbalBribery)
                }
            }
        }
    }
    
    func startFootballBriberyTrial(_ courtCase: FootballBriberyCase) {
        
        if let guilty: Player = self.centralbank.dataStore.find(uuid: courtCase.accusedUUID) {
            let fine = courtCase.illegalWin * 3
            let invoice = Invoice(title: "Bribery trial fine", grossValue: fine, taxRate: 0)
            let transaction = FinancialTransaction(payerUUID: guilty.uuid, recipientUUID: SystemPlayer.government.uuid, invoice: invoice, type: .fine)
            try? self.centralbank.process(transaction, checkWalletCapacity: false)
            let verdict = "\(guilty.login) was found guilty of bribing referee \(courtCase.bribedReferees.joined(separator: ", ")) and thus making illegal income from football bets. Court sentenced \(guilty.login) to pay \(fine.money) fine. No jailtime this time."
            self.delegate?.notify(playerUUID: guilty.uuid, UINotification(text: verdict, level: .warning, duration: 60))
            self.delegate?.syncWalletChange(playerUUID: guilty.uuid)
        }
        self.cases.removeAll{ $0.uuid == courtCase.uuid }
    }
}

enum CourtCaseType {
    case footballMatchBribery
}

protocol CourtCase {
    var uuid: String { get }
    var type: CourtCaseType { get }
    var accusedUUID: String { get }
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
