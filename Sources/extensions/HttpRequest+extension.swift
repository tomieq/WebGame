//
//  HttpRequest+extension.swift
//
//
//  Created by Tomasz Kucharski on 19/03/2021.
//

import Foundation
import Swifter

extension HttpRequest {
    var mapPoint: MapPoint? {
        guard let xText = self.queryParams.get("x"),
              let yText = self.queryParams.get("y"), let x = Int(xText), let y = Int(yText) else {
            return nil
        }
        return MapPoint(x: x, y: y)
    }
    
    var windowIndex: String? {
        self.queryParams.get("windowIndex")
    }
    
    var playerSessionID: String? {
        self.queryParams.get("playerSessionID")
    }
}
