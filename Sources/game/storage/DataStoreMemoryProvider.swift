//
//  DataStoreMemoryProvider.swift
//
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

class DataStoreMemoryProvider: DataStoreProvider {
    private var players: [PlayerManagedObject]
    private var transactions: [CashFlowManagedObject]
    private var register: [PropertyRegisterManagedObject]
    private var lands: [LandManagedObject]
    private var roads: [RoadManagedObject]
    private var parkings: [ParkingManagedObject]
    private var buildings: [ResidentialBuildingManagedObject]
    private var apartments: [ApartmentManagedObject]
    private var adverts: [SaleAdvertManagedObject]

    private var playerQueue = DispatchQueue(label: "DataStore.Player.queue", attributes: .concurrent)
    private var cashQueue = DispatchQueue(label: "DataStore.CashFlow.queue", attributes: .concurrent)
    private var landQueue = DispatchQueue(label: "DataStore.Land.queue", attributes: .concurrent)
    private var roadQueue = DispatchQueue(label: "DataStore.Road.queue", attributes: .concurrent)
    private var propertyQueue = DispatchQueue(label: "DataStore.Road.queue", attributes: .concurrent)
    private var residentialBuildingQueue = DispatchQueue(label: "DataStore.ResidentialBuilding.queue", attributes: .concurrent)
    private var queue = DispatchQueue(label: "DataStore.Other.queue", attributes: .concurrent)

    init() {
        self.players = []
        self.transactions = []
        self.register = []
        self.lands = []
        self.roads = []
        self.parkings = []
        self.buildings = []
        self.apartments = []
        self.adverts = []
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
        return self.cashQueue.sync(flags: .barrier) {
            let managedObject = CashFlowManagedObject(transaction)
            self.transactions.append(managedObject)
            return managedObject.uuid
        }
    }

    func getFinancialTransactions(userID: String) -> [CashFlow] {
        return self.cashQueue.sync {
            self.transactions.filter{ $0.playerID == userID }.sorted { $0.id > $1.id }.map{ CashFlow($0) }
        }
    }

    @discardableResult
    func create(_ land: Land) -> String {
        return self.landQueue.sync(flags: .barrier) {
            let managedObject = LandManagedObject(land)
            self.lands.append(managedObject)
            return managedObject.uuid
        }
    }

    // MARK: Land
    func find(address: MapPoint) -> Land? {
        return self.landQueue.sync {
            self.lands.first{ $0.x == address.x && $0.y == address.y }.map { Land($0) }
        }
    }

    func getAll() -> [Land] {
        return self.landQueue.sync {
            self.lands.map { Land($0) }
        }
    }

    func removeLand(uuid: String) {
        self.landQueue.sync(flags: .barrier) {
            self.lands.removeAll{ $0.uuid == uuid }
        }
    }

    func update(_ mutation: LandMutation) {
        self.landQueue.sync(flags: .barrier) {
            guard let land = (self.lands.first{ $0.uuid == mutation.uuid }) else { return }

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
        }
    }

    // MARK: Road
    @discardableResult
    func create(_ road: Road) -> String {
        return self.roadQueue.sync(flags: .barrier) {
            let managedObject = RoadManagedObject(road)
            self.roads.append(managedObject)
            return managedObject.uuid
        }
    }

    func find(address: MapPoint) -> Road? {
        return self.roadQueue.sync {
            self.roads.first{ $0.x == address.x && $0.y == address.y }.map { Road($0) }
        }
    }

    func getAll() -> [Road] {
        return self.roadQueue.sync {
            self.roads.map { Road($0) }
        }
    }

    func getUnderConstruction() -> [Road] {
        return self.roadQueue.sync {
            self.roads.filter{ $0.isUnderConstruction }.map { Road($0) }
        }
    }

    func removeRoad(uuid: String) {
        self.roadQueue.sync(flags: .barrier) {
            self.roads.removeAll{ $0.uuid == uuid }
        }
    }

    func update(_ mutation: RoadMutation) {
        self.roadQueue.sync(flags: .barrier) {
            guard let road = (self.roads.first{ $0.uuid == mutation.uuid }) else { return }

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
        }
    }

    // MARK: ResidentialBuilding
    @discardableResult
    func create(_ building: ResidentialBuilding) -> String {
        return self.residentialBuildingQueue.sync(flags: .barrier) {
            let managedObject = ResidentialBuildingManagedObject(building)
            self.buildings.append(managedObject)
            return managedObject.uuid
        }
    }

    func find(address: MapPoint) -> ResidentialBuilding? {
        return self.residentialBuildingQueue.sync {
            return self.buildings.first{ $0.x == address.x && $0.y == address.y }.map { ResidentialBuilding($0) }
        }
    }

    func getAll() -> [ResidentialBuilding] {
        return self.residentialBuildingQueue.sync {
            self.buildings.map { ResidentialBuilding($0) }
        }
    }

    func getUnderConstruction() -> [ResidentialBuilding] {
        return self.residentialBuildingQueue.sync {
            self.buildings.filter{ $0.isUnderConstruction }.map { ResidentialBuilding($0) }
        }
    }

    func removeResidentialBuilding(uuid: String) {
        self.residentialBuildingQueue.sync(flags: .barrier) {
            self.buildings.removeAll{ $0.uuid == uuid }
        }
    }

    func update(_ mutation: ResidentialBuildingMutation) {
        self.residentialBuildingQueue.sync(flags: .barrier) {
            guard let building = (self.buildings.first{ $0.uuid == mutation.uuid }) else { return }

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
        }
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
        return self.roadQueue.sync(flags: .barrier) {
            let managedObject = ParkingManagedObject(parking)
            self.parkings.append(managedObject)
            return managedObject.uuid
        }
    }

    func find(address: MapPoint) -> Parking? {
        return self.roadQueue.sync {
            self.parkings.first{ $0.x == address.x && $0.y == address.y }.map { Parking($0) }
        }
    }

    func getAll() -> [Parking] {
        return self.roadQueue.sync {
            self.parkings.map { Parking($0) }
        }
    }

    func getUnderConstruction() -> [Parking] {
        return self.roadQueue.sync {
            self.parkings.filter{ $0.isUnderConstruction }.map { Parking($0) }
        }
    }

    func update(_ mutation: ParkingMutation) {
        self.roadQueue.sync(flags: .barrier) {
            guard let parking = (self.parkings.first{ $0.uuid == mutation.uuid }) else { return }

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
        }
    }

    // MARK: Apartment
    @discardableResult func create(_ apartment: Apartment) -> String {
        return self.residentialBuildingQueue.sync(flags: .barrier) {
            let managedObject = ApartmentManagedObject(apartment)
            self.apartments.append(managedObject)
            return managedObject.uuid
        }
    }

    func get(address: MapPoint) -> [Apartment] {
        return self.residentialBuildingQueue.sync {
            return self.apartments.filter{ $0.x == address.x && $0.y == address.y }.map { Apartment($0) }
        }
    }

    func find(uuid: String) -> Apartment? {
        return self.residentialBuildingQueue.sync {
            return self.apartments.first{ $0.uuid == uuid }.map { Apartment($0) }
        }
    }
}
