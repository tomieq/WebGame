//
//  Police.swift
//  
//
//  Created by Tomasz Kucharski on 29/10/2021.
//

import Foundation

class Police {
    let footballBookie: FootballBookie
    var investigations: [PoliceInvestigation]
    
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
        for archive in bookie.getArchive() {
            if archive.match.isSuspected {
                numberOfSuspectedMatches += 1
            }
        }
        if numberOfSuspectedMatches > 1 {
            self.investigations.append(PoliceInvestigation(type: .footballMatchBribery))
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
    
    init(type: PoliceInvestigationType) {
        self.uuid = UUID().uuidString
        self.type = type
    }
}
