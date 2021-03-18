//
//  JSCode.swift
//  
//
//  Created by Tomasz Kucharski on 18/03/2021.
//

import Foundation
import Swifter

class JSResponse {
    private var code: [JSCode] = []
    var response: HttpResponse {
        return .ok(.text(self.code.map{ $0.js }.joined(separator: "\n")))
    }
    
    @discardableResult
    func add(_ code: JSCode) -> JSResponse {
        self.code.append(code)
        return self
    }
}

enum JSCode {
    case setWindowContent(String, content: String)
}

extension JSCode {
    var js: String {
        switch self {
        case .setWindowContent(let windowIndex, content: let content):
            return "setWindowContent(\(windowIndex), \"\(content)\");";
        }
    }
}
