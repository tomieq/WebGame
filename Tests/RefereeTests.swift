//
//  RefereeTests.swift
//  
//
//  Created by Tomasz Kucharski on 31/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

class RefereeTests: XCTestCase {
    
    func test_tooSmallBribe() {
        let referee = self.makeReferee()
        
        XCTAssertThrowsError(try referee.bribe(playerUUID: "gambler", matchUUID: "", amount: 100.0)){ error in
            XCTAssertEqual(error as? RefereeError, .bribeTooSmall)
        }
    }
    
    func test_bribeFromTwoUsersBettingTheSame() {
        
    }
    
    func test_bribeFromTwoUsersBettingDifferent() {
        
    }
    
    func test_bribeFromUserWithoutEnoughMoneyInWallet() {
        
    }
    
    private func makeReferee() -> Referee {
        let referee = Referee()
        return referee
    }
}
