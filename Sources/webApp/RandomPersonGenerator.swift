//
//  RandomPersonGenerator.swift
//
//
//  Created by Tomasz Kucharski on 28/10/2021.
//

import Foundation

class RandomPersonGenerator {
    static func getName() -> String {
        let name = RandomPersonGenerator.shared?.names.randomElement() ?? "Joe"
        let surname = RandomPersonGenerator.shared?.surnames.randomElement() ?? "Doe"
        return "\(name) \(surname)"
    }

    private static let shared = RandomPersonGenerator()
    let names: [String]
    let surnames: [String]

    init?() {
        let decoder = JSONDecoder()

        do {
            var url = URL(fileURLWithPath: Resource.absolutePath(forAppResource: "data/first-names.json"))
            var data = try Data(contentsOf: url)
            self.names = try decoder.decode([String].self, from: data)
            url = URL(fileURLWithPath: Resource.absolutePath(forAppResource: "data/last-names.json"))
            data = try Data(contentsOf: url)
            self.surnames = try decoder.decode([String].self, from: data)
        } catch {
            print("Failed to decode JSON \(error)")
            return nil
        }
    }
}
