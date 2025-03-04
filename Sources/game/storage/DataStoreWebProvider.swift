//
//  DataStoreMemoryProvider.swift
//
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation
import WebRequest

class DataStoreWebProvider: DataStoreProvider {
    private var players: [PlayerManagedObject]
    private var register: [PropertyRegisterManagedObject]
    private var adverts: [SaleAdvertManagedObject]

    private var playerQueue = DispatchQueue(label: "DataStore.Player.queue", attributes: .concurrent)
    private var propertyQueue = DispatchQueue(label: "DataStore.Road.queue", attributes: .concurrent)
    private var queue = DispatchQueue(label: "DataStore.Other.queue", attributes: .concurrent)

    init() {
        WebRequestConfig.timeout = 20
        self.players = []
        self.register = []
        self.adverts = []
    }
    
    let dbVersion = "webGame_v12"
    let dbHost = "http://localhost:8080"
    private func get<T:Codable>(type: String, id: Int) -> T? {
        let response: WebRequest<T> = .get(url: "\(dbHost)/\(dbVersion)/data/\(type)/\(id)")
        switch response {
        case .failure(let error):
            Logger.info("DataStoreWebProvider", "get \(type) error: \(error)")
            return nil
        case .response(let value):
            return value
        }
    }
    private func getList<T:Codable>(type: String, filters: [String:CustomStringConvertible]) -> [T] {
        let query = filters.map{ "\($0.key)=\($0.value)" }.joined(separator: "&")
        let response: WebRequest<[T]> = .get(url: "\(dbHost)/\(dbVersion)/data/\(type)?\(query)")
        switch response {
        case .failure(let error):
            Logger.info("DataStoreWebProvider", "getList \(type) error: \(error)")
            return []
        case .response(let value):
            return value
        }
    }
    
    private func create<T:Codable>(type: String, object: T) -> T? {
        let response: WebRequest<T> = .post(url: "\(dbHost)/\(dbVersion)/data/\(type)", body: object)
        switch response {
        case .failure(let error):
            Logger.info("DataStoreWebProvider", "create \(type) error: \(error)")
            return nil
        case .response(let value):
            return value
        }
    }

    private func update<T:Codable>(type: String, object: T, filters: [String:CustomStringConvertible]) {
        let query = filters.map{ "\($0.key)=\($0.value)" }.joined(separator: "&")
        let response: WebRequest<T> = .put(url: "\(dbHost)/\(dbVersion)/data/\(type)?\(query)", body: object)
        switch response {
        case .failure(let error):
            Logger.info("DataStoreWebProvider", "update \(type) error: \(error)")
            break
        case .response:
            break
        }
    }
    
    private func delete<T:Codable>(type: String, filters: [String:CustomStringConvertible]) -> T? {
        let query = filters.map{ "\($0.key)=\($0.value)" }.joined(separator: "&")
        let response: WebRequest<T> = .delete(url: "\(dbHost)/\(dbVersion)/data/\(type)?\(query)")
        switch response {
        case .failure(let error):
            Logger.info("DataStoreWebProvider", "delete \(type) error: \(error)")
            return nil
        case .response(let value):
            return value
        }
    }
    
    // MARK: Player
    @discardableResult
    func create(_ player: Player) -> String {
        return self.playerQueue.sync(flags: .barrier) {
            let managedPlayer = PlayerManagedObject(player)
            self.players.append(managedPlayer)
            return managedPlayer.uuid
        }
    }

    func find(uuid: String) -> Player? {
        return self.playerQueue.sync {
            self.players.first { $0.uuid == uuid }.map{ Player($0) }
        }
    }

    func getAll() -> [Player] {
        return self.playerQueue.sync {
            self.players.map{ Player($0) }
        }
    }

    func removePlayer(id: String) {
        self.playerQueue.sync(flags: .barrier) {
            self.players.removeAll{ $0.uuid == id }
        }
    }

    func update(_ mutation: PlayerMutation) {
        self.playerQueue.sync(flags: .barrier) {
            guard let managedPlayer = (self.players.first{ $0.uuid == mutation.uuid }) else { return }
            for attribute in mutation.attributes {
                switch attribute {
                case .wallet(let value):
                    managedPlayer.wallet = value
                }
            }
        }
    }

    // MARK: CashFlow
    @discardableResult func create(_ transaction: CashFlow) -> String {
        let localObject = CashFlowManagedObject(transaction)
        let _ = self.create(type: "CashFlow", object: localObject)
        return localObject.uuid
    }

    func getFinancialTransactions(userID: String) -> [CashFlow] {
        let objects: [CashFlowManagedObject] = self.getList(type: "CashFlow", filters: ["playerID":userID])
        return objects.sorted { $0.id ?? 0 > $1.id ?? 0 }.map { CashFlow($0) }
    }

    @discardableResult
    func create(_ land: Land) -> String {
        let localObject = LandManagedObject(land)
        let _ = self.create(type: "Lands", object: localObject)
        return localObject.uuid
    }

    // MARK: Land
    func find(address: MapPoint) -> Land? {
        let objects: [LandManagedObject] = self.getList(type: "Lands", filters: ["x":address.x, "y":address.y])
        return objects.map { Land($0) }.first
    }

    func getAll() -> [Land] {
        let objects: [LandManagedObject] = self.getList(type: "Lands", filters: [:])
        return objects.map { Land($0) }
    }

    func removeLand(uuid: String) {
        let _: LandManagedObject? = self.delete(type: "Lands", filters: ["uuid":uuid])
    }

    func update(_ mutation: LandMutation) {
        class LandUpdate: Codable {
            var isUnderConstruction: Bool?
            var constructionFinishMonth: Int?
            var ownerUUID: String?
            var purchaseNetValue: Double?
            var investmentsNetValue: Double?
        }
        let land = LandUpdate()
        for attribute in mutation.attributes {
            switch attribute {
            case .isUnderConstruction(let value):
                land.isUnderConstruction = value
            case .constructionFinishMonth(let value):
                land.constructionFinishMonth = value
            case .ownerUUID(let value):
                land.ownerUUID = value
            case .purchaseNetValue(let value):
                land.purchaseNetValue = value
            case .investments(let value):
                land.investmentsNetValue = value
            }
        }
        self.update(type: "Lands", object: land, filters: ["uuid":mutation.uuid])
    }

    // MARK: Road
    @discardableResult
    func create(_ road: Road) -> String {
        let localObject = RoadManagedObject(road)
        let _ = self.create(type: "Roads", object: localObject)
        return localObject.uuid
    }

    func find(address: MapPoint) -> Road? {
        let objects: [RoadManagedObject] = self.getList(type: "Roads", filters: ["x":address.x, "y":address.y])
        return objects.map { Road($0) }.first
    }

    func getAll() -> [Road] {
        let objects: [RoadManagedObject] = self.getList(type: "Roads", filters: [:])
        return objects.map { Road($0) }
    }

    func getUnderConstruction() -> [Road] {
        let objects: [RoadManagedObject] = self.getList(type: "Roads", filters: ["isUnderConstruction":"true"])
        return objects.map { Road($0) }
    }

    func removeRoad(uuid: String) {
        let _: RoadManagedObject? = self.delete(type: "Roads", filters: ["uuid":uuid])
    }

    func update(_ mutation: RoadMutation) {
        class RoadUpdate: Codable {
            var isUnderConstruction: Bool?
            var constructionFinishMonth: Int?
            var ownerUUID: String?
            var purchaseNetValue: Double?
            var investmentsNetValue: Double?
        }
        let road = RoadUpdate()
        for attribute in mutation.attributes {
            switch attribute {
            case .isUnderConstruction(let value):
                road.isUnderConstruction = value
            case .constructionFinishMonth(let value):
                road.constructionFinishMonth = value
            case .ownerUUID(let value):
                road.ownerUUID = value
            case .purchaseNetValue(let value):
                road.purchaseNetValue = value
            }
        }
        self.update(type: "Roads", object: road, filters: ["uuid":mutation.uuid])
    }

    // MARK: ResidentialBuilding
    @discardableResult
    func create(_ building: ResidentialBuilding) -> String {
        let localObject = ResidentialBuildingManagedObject(building)
        let _ = self.create(type: "Buildings", object: localObject)
        return localObject.uuid
    }

    func find(address: MapPoint) -> ResidentialBuilding? {
        let objects: [ResidentialBuildingManagedObject] = self.getList(type: "Buildings", filters: ["x":address.x, "y":address.y])
        return objects.map { ResidentialBuilding($0) }.first
    }

    func getAll() -> [ResidentialBuilding] {
        let objects: [ResidentialBuildingManagedObject] = self.getList(type: "Buildings", filters: [:])
        return objects.map { ResidentialBuilding($0) }
    }

    func getUnderConstruction() -> [ResidentialBuilding] {
        let objects: [ResidentialBuildingManagedObject] = self.getList(type: "Buildings", filters: ["isUnderConstruction":"true"])
        return objects.map { ResidentialBuilding($0) }
    }

    func removeResidentialBuilding(uuid: String) {
        let _: ResidentialBuildingManagedObject? = self.delete(type: "Buildings", filters: ["uuid":uuid])
    }

    func update(_ mutation: ResidentialBuildingMutation) {
        class BuildingUpdate: Codable {
            var isUnderConstruction: Bool?
            var constructionFinishMonth: Int?
            var ownerUUID: String?
            var purchaseNetValue: Double?
            var investmentsNetValue: Double?
        }
        let building = BuildingUpdate()
        for attribute in mutation.attributes {
            switch attribute {
            case .isUnderConstruction(let value):
                building.isUnderConstruction = value
            case .constructionFinishMonth(let value):
                building.constructionFinishMonth = value
            case .ownerUUID(let value):
                building.ownerUUID = value
            case .purchaseNetValue(let value):
                building.purchaseNetValue = value
            case .investmentsNetValue(let value):
                building.investmentsNetValue = value
            }
        }
        self.update(type: "Buildings", object: building, filters: ["uuid":mutation.uuid])
    }

    // MARK: SaleAdvert
    @discardableResult
    func create(_ advert: SaleAdvert) -> String {
        return self.queue.sync(flags: .barrier) {
            let managedObject = SaleAdvertManagedObject(advert)
            self.adverts.append(managedObject)
            return managedObject.uuid
        }
    }

    func find(address: MapPoint) -> SaleAdvert? {
        return self.queue.sync {
            return self.adverts.first{ $0.x == address.x && $0.y == address.y }.map{ SaleAdvert($0) }
        }
    }

    func getAll() -> [SaleAdvert] {
        return self.queue.sync {
            self.adverts.map { SaleAdvert($0) }
        }
    }

    func update(_ mutation: SaleAdvertMutation) {
        self.queue.sync(flags: .barrier) {
            guard let advert = (self.adverts.first{ $0.x == mutation.address.x && $0.y == mutation.address.y }) else { return }
            for attribute in mutation.attributes {
                switch attribute {
                case .netPrice(let value):
                    advert.netPrice = value
                }
            }
        }
    }

    func removeSaleAdvert(address: MapPoint) {
        self.queue.sync(flags: .barrier) {
            self.adverts.removeAll{ $0.x == address.x && $0.y == address.y }
        }
    }

    // MARK: PropertyRegister
    func create(_ register: PropertyRegister) -> String {
        return self.propertyQueue.sync(flags: .barrier) {
            let managedObject = PropertyRegisterManagedObject(register)
            self.register.append(managedObject)
            return managedObject.uuid
        }
    }

    func find(uuid: String) -> PropertyRegister? {
        return self.propertyQueue.sync {
            return self.register.first{ $0.uuid == uuid }.map{ PropertyRegister($0) }
        }
    }

    func get(ownerUUID: String) -> [PropertyRegister] {
        return self.propertyQueue.sync {
            return self.register.filter{ $0.ownerUUID == ownerUUID }.map{ PropertyRegister($0) }
        }
    }

    func update(_ mutation: PropertyRegisterMutation) {
        self.propertyQueue.sync(flags: .barrier) {
            guard let managedObject = (self.register.first{ $0.uuid == mutation.uuid }) else { return }
            for attribute in mutation.attributes {
                switch attribute {
                case .ownerUUID(let value):
                    managedObject.ownerUUID = value
                case .type(let value):
                    managedObject.type = value
                case .status(let value):
                    managedObject.status = value
                }
            }
        }
    }

    func removePropertyRegister(uuid: String) {
        self.propertyQueue.sync(flags: .barrier) {
            self.register.removeAll{ $0.uuid == uuid }
        }
    }

    // MARK: Parking
    func create(_ parking: Parking) -> String {
        let localObject = ParkingManagedObject(parking)
        let _ = self.create(type: "Parkings", object: localObject)
        return localObject.uuid
    }

    func find(address: MapPoint) -> Parking? {
        let objects: [ParkingManagedObject] = self.getList(type: "Parkings", filters: ["x":address.x, "y":address.y])
        return objects.map { Parking($0) }.first
    }

    func getAll() -> [Parking] {
        let objects: [ParkingManagedObject] = self.getList(type: "Parkings", filters: [:])
        return objects.map { Parking($0) }
    }

    func getUnderConstruction() -> [Parking] {
        let objects: [ParkingManagedObject] = self.getList(type: "Parkings", filters: ["isUnderConstruction":"true"])
        return objects.map { Parking($0) }
    }

    func update(_ mutation: ParkingMutation) {
        class ParkingUpdate: Codable {
            var isUnderConstruction: Bool?
            var constructionFinishMonth: Int?
            var ownerUUID: String?
            var purchaseNetValue: Double?
            var investmentsNetValue: Double?
            var insurance: String?
            var security: String?
            var advertising: String?
            var trustLevel: Double?
        }
        let parking = ParkingUpdate()
        for attribute in mutation.attributes {
            switch attribute {
            case .isUnderConstruction(let value):
                parking.isUnderConstruction = value
            case .constructionFinishMonth(let value):
                parking.constructionFinishMonth = value
            case .ownerUUID(let value):
                parking.ownerUUID = value
            case .purchaseNetValue(let value):
                parking.purchaseNetValue = value
            case .investments(let value):
                parking.investmentsNetValue = value
            case .insurance(let value):
                parking.insurance = value.rawValue
            case .security(let value):
                parking.security = value.rawValue
            case .advertising(let value):
                parking.advertising = value.rawValue
            case .trustLevel(let value):
                var value = value
                if value > 1 { value = 1 }
                if value < 0 { value = 0 }
                parking.trustLevel = value
            }
        }
        self.update(type: "Parkings", object: parking, filters: ["uuid":mutation.uuid])
    }

    // MARK: Apartment
    @discardableResult func create(_ apartment: Apartment) -> String {
        let localObject = ApartmentManagedObject(apartment)
        let _ = self.create(type: "Apartments", object: localObject)
        return localObject.uuid
    }

    func get(address: MapPoint) -> [Apartment] {
        let objects: [ApartmentManagedObject] = self.getList(type: "Apartments", filters: ["x":address.x, "y":address.y])
        return objects.map { Apartment($0) }
    }

    func find(uuid: String) -> Apartment? {
        let objects: [ApartmentManagedObject] = self.getList(type: "Apartments", filters: ["uuid":uuid])
        return objects.map { Apartment($0) }.first
    }
}
