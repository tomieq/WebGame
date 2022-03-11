//
//  GameEventBus.swift
//
//
//  Created by Tomasz Kucharski on 17/03/2021.
//

import Foundation
import RxSwift

class GameEventBus {
    static let gameEvents = PublishSubject<GameEvent>()

    private init() {}
}
