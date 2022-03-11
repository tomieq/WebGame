//
//  PropertyManagerTopView.swift
//
//
//  Created by Tomasz Kucharski on 05/11/2021.
//

import Foundation

class PropertyManagerTopView {
    private var data: [String: String] = [:]
    private var tips: [String] = []
    private var tabs: [[String: String]] = []

    init(windowIndex: String) {
        self.data["tabDetailsID"] = PropertyManagerTopView.domID(windowIndex)
    }

    public static func domID(_ windowIndex: String) -> String {
        return "content\(windowIndex)"
    }

    @discardableResult
    func setTileImage(_ path: String) -> PropertyManagerTopView {
        self.data["tileUrl"] = path
        return self
    }

    @discardableResult
    func setPropertyType(_ type: String) -> PropertyManagerTopView {
        self.data["type"] = type
        return self
    }

    @discardableResult
    func addTip(_ tip: String) -> PropertyManagerTopView {
        self.tips.append(tip)
        return self
    }

    @discardableResult
    func addTab(_ name: String, onclick: JSCode) -> PropertyManagerTopView {
        var tabData: [String: String] = [:]
        tabData["name"] = name
        tabData["onclick"] = "\(onclick.js); $('.tabItem').removeClass('activeTabItem'); $(this).addClass('activeTabItem');"
        self.tabs.append(tabData)
        return self
    }

    @discardableResult
    func setInitialContent(html: String) -> PropertyManagerTopView {
        self.data["initialContent"] = html
        return self
    }

    func output() -> String {
        let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManager/topView.html"))
        template.assign(variables: self.data)
        for tip in self.tips {
            template.assign(variables: ["text": tip], inNest: "tip")
        }
        for (index, tab) in self.tabs.enumerated() {
            var tabData = tab
            if index == 0 { tabData["activeCss"] = "activeTabItem" }
            template.assign(variables: tabData, inNest: "tab")
        }
        return template.output()
    }
}
