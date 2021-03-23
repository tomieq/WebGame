//
//  JSCode.swift
//  
//
//  Created by Tomasz Kucharski on 18/03/2021.
//

import Foundation
import Swifter

class JSResponse {
    private var jsCodeList: [JSCode] = []
    var response: HttpResponse {
        return .ok(.javaScript(self.jsCodeList.map{ $0.js }.joined(separator: "\n")))
    }
    
    @discardableResult
    func add(_ code: JSCode) -> JSResponse {
        self.jsCodeList.append(code)
        return self
    }
}

enum JSCode {
    case setWindowContent(String, content: String)
    case setWindowTitle(String, title: String)
    case setWindowActive(String)
    case resizeWindow(String, width: Int, height: Int)
    case disableWindowResizing(String)
    case centerWindowHorizontally(String)
    case centerWindowVertically(String)
    case centerWindow(String)
    case closeWindow(String)
    case runScripts(String, paths: [String])
    case loadHtml(String, htmlPath: String)
    case loadHtmlThenRunScripts(String, htmlPath: String, scriptPaths: [String])
    case loadJsAndHtmlThenRunScripts(String, jsFilePaths: [String], htmlPath: String, scriptPaths: [String])
    case showError(txt: String, duration: Int)
    case showWarning(txt: String, duration: Int)
    case showSuccess(txt: String, duration: Int)
    case showInfo(txt: String, duration: Int)
    case any(String)
}

extension JSCode {
    var js: String {
        switch self {
        case .setWindowContent(let windowIndex, let content):
            return "setWindowContent(\(windowIndex), '\(content.escaped)');";
        case .setWindowTitle(let windowIndex, let title):
            return "setWindowTitle(\(windowIndex), '\(title.escaped)');"
        case .setWindowActive(let windowIndex):
            return "setWindowActive(\(windowIndex));";
        case .resizeWindow(let windowIndex, let width, let height):
            return "resizeWindow(\(windowIndex), \(width), \(height));";
        case .disableWindowResizing(let windowIndex):
            return "disableWindowResizing(\(windowIndex));"
        case .centerWindowHorizontally(let windowIndex):
            return "centerWindowHorizontally(\(windowIndex));"
        case .centerWindowVertically(let windowIndex):
            return "centerWindowVertically(\(windowIndex));"
        case .centerWindow(let windowIndex):
            return "centerWindow(\(windowIndex));"
        case .closeWindow(let windowIndex):
             return "closeWindow(\(windowIndex));";
        case .loadHtml(let windowIndex, let htmlPath):
            return "loadHtmlThenRunScripts(\(windowIndex), '\(htmlPath)', [], '');";
        case .loadHtmlThenRunScripts(let windowIndex, let htmlPath, let scriptPaths):
            return "loadHtmlThenRunScripts(\(windowIndex), '\(htmlPath)', ['\(scriptPaths.joined(separator: "', '"))'], '');";
        case .loadJsAndHtmlThenRunScripts(let windowIndex, let jsFilePaths, let htmlPath, let scriptPaths):
            return "loadJsAndHtmlThenRunScripts(\(windowIndex), ['\(jsFilePaths.joined(separator: "', '"))'], '\(htmlPath)', ['\(scriptPaths.joined(separator: "', '"))'], '');";
        case .runScripts(let windowIndex, let paths):
            return "runScripts(\(windowIndex), ['\(paths.joined(separator: "', '"))']);"
        case .showError(let txt, let duration):
            return "uiShowError('\(txt.escaped)', \(duration * 1000));";
        case .showWarning(let txt, let duration):
            return "uiShowWarning('\(txt.escaped)', \(duration * 1000));";
        case .showSuccess(let txt, let duration):
            return "uiShowSuccess(\'(\(txt.escaped))', \(duration * 1000));";
        case .showInfo(let txt, let duration):
            return "uiShowInfo('\(txt.escaped)', \(duration * 1000));";
        case .any(let code):
            return code
        }
    }
}

extension JSCode {
    var response: HttpResponse {
        return .ok(.javaScript(self.js))
    }
}

fileprivate extension String {
    var escaped: String {
        return self.replacingOccurrences(of: "'", with: "\\'")
    }
}
