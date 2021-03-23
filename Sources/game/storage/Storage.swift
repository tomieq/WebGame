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
    
    private init() {
        
        self.players = [Player(id: "p1", login: "John"), Player(id: "p2", login: "Steve")]
        self.landProperties = []
        self.save()
        _ = StorageCoordinator.shared
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