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
    
    init(footballBookie: FootballBookie) {
        self.footballBookie = footballBookie
        self.investigations = []
    }
    
    func nextMonth() {
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
            notice.append("They might close the case if they find nothing or they might route the case to Court if they find any evidence of illegal activity.")
            
            for suspectUUID in suspectsUUIDs.unique {
                self.delegate?.notify(playerUUID: suspectUUID, UINotification(text: notice, level: .warning, duration: 30))
            }
        }
    }
    
    func finishInvestigation(_ investigation: PoliceInvestigation) {
        self.investigations.removeAll{ $0.uuid == investigation.uuid }
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
