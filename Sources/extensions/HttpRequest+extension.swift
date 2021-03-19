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
        guard let xText = self.queryParam("x"), let yText = self.queryParam("y"), let x = Int(xText), let y = Int(yText) else {
            return nil
        }
        return MapPoint(x: x, y: y)
    }
}
