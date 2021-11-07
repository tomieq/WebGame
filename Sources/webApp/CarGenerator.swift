//
//  CarGenerator.swift
//  
//
//  Created by Tomasz Kucharski on 07/11/2021.
//

import Foundation

class CarGenerator {
    private let data: [CarDto]
    static let shared = CarGenerator()
    
    init() {
        let decoder = JSONDecoder()
        do {
            let url = URL(fileURLWithPath: Resource.absolutePath(forAppResource: "data/cars.json"))
            let data = try Data(contentsOf: url)
            self.data = try decoder.decode([CarDto].self, from: data)
        } catch {
            Logger.error("CarGenerator", "Failed to decode JSON \(error)")
            self.data = []
        }

    }
    
    func ramdomCar() -> String {
        if let car = self.data.randomElement(), let brand = car.brand, let model = car.models.randomElement() {
            return "\(brand) \(model)"
        }
        return ""
    }
    
}

fileprivate class CarDto: Codable {
    var brand: String?
    var models: [String] = []
    

}
