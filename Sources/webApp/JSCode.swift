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
        return .ok(.javaScript(self.code.map{ $0.js }.joined(separator: "\n")))
    }
    
    @discardableResult
    func add(_ code: JSCode) -> JSResponse {
        self.code.append(code)
        return self
    }
}

enum JSCode {
    case setWindowContent(String, content: String)
    case setWindowActive(String)
    case resizeWindow(String, width: Int, height: Int)
    case closeWindow(String)
    case showError(txt: String, duration: Int)
    case showWarning(txt: String, duration: Int)
    case showSuccess(txt: String, duration: Int)
    case showInfo(txt: String, duration: Int)
}

extension JSCode {
    var js: String {
        switch self {
        case .setWindowContent(let windowIndex, let content):
            return "setWindowContent(\(windowIndex), \"\(content)\");";
        case .setWindowActive(let windowIndex):
            return "setWindowActive(\(windowIndex));";
        case .resizeWindow(let windowIndex, let width, let height):
            return "resizeWindow(\(windowIndex), \(width), \(height));";
        case .closeWindow(let windowIndex):
             return "closeWindow(\(windowIndex));";
        case .showError(let txt, let duration):
            return "uiShowError(\"\(txt)\", \(duration * 1000));";
        case .showWarning(let txt, let duration):
            return "uiShowWarning(\"\(txt)\", \(duration * 1000));";
        case .showSuccess(let txt, let duration):
            return "uiShowSuccess(\"\(txt)\", \(duration * 1000));";
        case .showInfo(let txt, let duration):
            return "uiShowInfo(\"\(txt)\", \(duration * 1000));";
        }
    }
}
