//
//  GameClock.swift
//
//
//  Created by Tomasz Kucharski on 25/03/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol GameClockDelegate {
    func nextMonth()
    func syncTime()
}

class GameClock {
    let realEstateAgent: RealEstateAgent
    let time: GameTime
    let secondsPerMonth: Int
    private var secondsCounter: Int
    private let dataStore: DataStoreProvider
    var delegate: GameClockDelegate?
    private let disposeBag = DisposeBag()

    var secondsLeft: Int {
        self.secondsPerMonth - self.secondsCounter
    }

    init(realEstateAgent: RealEstateAgent, time: GameTime, secondsPerMonth: Int) {
        self.time = time
        self.realEstateAgent = realEstateAgent
        self.dataStore = realEstateAgent.dataStore
        self.delegate = nil
        self.secondsPerMonth = secondsPerMonth
        self.secondsCounter = 0

        Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).bind { [weak self] number in
            guard let `self` = self else { return }
            self.secondsCounter += 1

            if self.secondsCounter == self.secondsPerMonth {
                self.secondsCounter = 0

                Logger.info("GameClock", "End of the month")
                self.time.nextMonth()
                self.delegate?.nextMonth()
            } else if self.secondsCounter % 60 == 0 {
                self.delegate?.syncTime()
            }
        }.disposed(by: self.disposeBag)
    }
}
