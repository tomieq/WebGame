//
//  Storage.swift
//  
//
//  Created by Tomasz Kucharski on 23/03/2021.
//

import Foundation
import RxSwift

class Storage: Codable {
    
    public static let shared = Storage.restore() ?? Storage()
    var players: [Player]
    var landProperties: [Land]
    var roadProperties: [Road]
    var residentialBuildings: [ResidentialBuilding]
    var apartments: [Apartment]
    var monthIteration: Int
    
    private init() {
        
        self.monthIteration = 0
        self.players = []
        for id in SystemPlayerID.allCases {
            self.players.append(Player(id: id.rawValue, login: id.login, type: .system, wallet: 0))
        }
        self.players.append(Player(id: "p1", login: "John Cash"))
        self.players.append(Player(id: "p2", login: "Steve Poor"))
        self.landProperties = []
        self.roadProperties = []
        self.residentialBuildings = []
        self.apartments = []
        self.save()
        _ = StorageCoordinator.shared
    }
    
    func getPlayer(id: String) -> Player? {
        return self.players.first { $0.id == id }
    }
    
    func getApartment(id: String) -> Apartment? {
        return self.apartments.first{ $0.id == id }
    }
    
    func getApartments(address: MapPoint) -> [Apartment] {
        return self.apartments.filter{ $0.address == address }
    }
    
    private static func restore() -> Storage? {
        let path = Resource.absolutePath(forAppResource: "snapshot.json")
        if let storage = try? JSONDecoder().decode(Storage.self, from: Data(contentsOf: URL(fileURLWithPath: path))) {
            _ = StorageCoordinator.shared
            return storage
        }
        return nil
    }
    
    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let json = try encoder.encode(self)
            let path = Resource.absolutePath(forAppResource: "snapshot.json")
            try json.write(to: URL(fileURLWithPath: path))
        }
        catch {
            Logger.error("Stoage", "Save error: \(error.localizedDescription)")
        }
    }
    

}

class StorageCoordinator {
    
    public static let shared = StorageCoordinator()
    private let disposebag = DisposeBag()
    
    private init() {
        Observable<Int>.interval(.seconds(30), scheduler: MainScheduler.instance).bind { _ in
            Logger.info("StorageCoordinator", "State saved")
            Storage.shared.save()
        }.disposed(by: self.disposebag)
    }
}
