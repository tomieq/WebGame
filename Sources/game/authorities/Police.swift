//
//  Police.swift
//  
//
//  Created by Tomasz Kucharski on 29/10/2021.
//

import Foundation

protocol PoliceDelegate {
    func syncWalletChange(playerUUID: String)
    func notify(playerUUID: String, _ notification: UINotification)
}

class Police {
    let footballBookie: FootballBookie
    var investigations: [PoliceInvestigation]
    var delegate: PoliceDelegate?
    let court: Court
    
    init(footballBookie: FootballBookie, court: Court) {
        self.footballBookie = footballBookie
        self.investigations = []
        self.court = court
    }
    
    func controlEvents() {
        self.checkFootballMatches()
    }
    
    func checkFootballMatches() {
        let bookie = self.footballBookie
        if let investigation = (self.investigations.first{ $0.type == .footballMatchBribery }) {
            
            if bookie.getArchive().count == self.footballBookie.archiveCapacity,
               bookie.getArchive()[safeIndex: 0]?.match.isSuspected ?? false {
                self.finishInvestigation(investigation)
            }
            return
        }
        var numberOfSuspectedMatches = 0
        var suspectsUUIDs: [String] = []
        for archive in bookie.getArchive() {
            if archive.match.isSuspected {
                numberOfSuspectedMatches += 1
                if let briberUUID = archive.match.briberUUID {
                    suspectsUUIDs.append(briberUUID)
                }
            }
        }
        if numberOfSuspectedMatches > 1 {
            let name = "Suspicious concidence with football match results"
            self.investigations.append(PoliceInvestigation(type: .footballMatchBribery, name: name))
            
            var notice = "Federal police started a new investigation: \(name). They will be checking last matches and investigating people. "
            notice.append("They might close the case if they find nothing or they might hand the case to Court if they find any evidence of illegal activity.")
            
            for suspectUUID in suspectsUUIDs.unique {
                self.delegate?.notify(playerUUID: suspectUUID, UINotification(text: notice, level: .warning, duration: 30))
            }
        }
    }
    
    func finishInvestigation(_ investigation: PoliceInvestigation) {
        switch investigation.type {
        case .footballMatchBribery:
            self.finishFootballBriberyInvestigation(investigation)
        }
        self.investigations.removeAll{ $0.uuid == investigation.uuid }
    }
    
    func finishFootballBriberyInvestigation(_ investigation: PoliceInvestigation) {
        class InvestigationProgress {
            var suspectUUID: String
            var fraud: Double = 0
            var referees: [String] = []
            
            init(suspectUUID: String) {
                self.suspectUUID = suspectUUID
            }
        }
        let bookie = self.footballBookie
        var progresses: [InvestigationProgress] = []
        for archive in bookie.getArchive() {
            let match = archive.match
            if let briberUUID = match.briberUUID {
                var progress = progresses.first{ $0.suspectUUID == briberUUID }
                if progress == nil {
                    progress = InvestigationProgress(suspectUUID: briberUUID)
                    progresses.append(progress!)
                }
                progress?.fraud += archive.bets.filter{ $0.playerUUID == briberUUID }.map{ (match.winRatio ?? 1) * $0.money}.reduce(0, +)
                progress?.referees.append(match.referee)
            }
        }
        for progress in progresses {
            self.court.registerNewCase(FootballBriberyCase(accusedUUID: progress.suspectUUID, illegalWin: progress.fraud, bribedReferees: progress.referees))
            let text = "Football match investigation revealed that you were involved in referee bribery. Federal police collected evidence and handed it to the Court. The trial will start soon."
            self.delegate?.notify(playerUUID: progress.suspectUUID, UINotification(text: text, level: .warning, duration: 60))
        }
    }
}

enum PoliceInvestigationType {
    case footballMatchBribery
}

struct PoliceInvestigation {
    let type: PoliceInvestigationType
    let uuid: String
    let name: String
    
    init(type: PoliceInvestigationType, name: String) {
        self.uuid = UUID().uuidString
        self.type = type
        self.name = name
    }
}
