//
//  Codable+extension.swift
//
//
//  Created by Tomasz Kucharski on 15/03/2021.
//

import Foundation

extension Encodable {
    func toJSONString() -> String? {
        return try? String(data: JSONEncoder().encode(self), encoding: .utf8)!
    }
}

extension Decodable {
    static func from(JSONString: String) -> Self? {
        guard let data = JSONString.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}
