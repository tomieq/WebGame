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
    private var buildings: [ResidentialBuildingManagedObject]
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
        self.buildings = []
        self.adverts = []
    }
    
    @discardableResult
    func create(_ player: Player) -> String {
        
        return playerQueue.sync(flags: .barrier) {
            let managedPlayer = PlayerManagedObject(player)
            self.players.append(managedPlayer)
            return managedPlayer.uuid
        }
    }
    
    func find(uuid: String) -> Player? {
        return playerQueue.sync {
            self.players.first { $0.uuid == uuid }.map{ Player($0) }
        }
    }
    
    func getAll() -> [Player] {
        return playerQueue.sync {
            self.players.map{ Player($0) }
        }
    }
    
    func removePlayer(id: String) {
        playerQueue.sync(flags: .barrier) {
            self.players.removeAll{ $0.uuid == id}
        }
    }

    func update(_ mutation: PlayerMutation) {
        playerQueue.sync(flags: .barrier) {
            guard let managedPlayer = (self.players.first{ $0.uuid == mutation.uuid }) else { return }
            for attribute in mutation.attributes {
                switch attribute {
                case .wallet(let value):
                    managedPlayer.wallet = value
                }
            }
        }
    }
    
    @discardableResult func create(_ transaction: CashFlow) -> String {
        
        return cashQueue.sync(flags: .barrier) {
            let managedObject = CashFlowManagedObject(transaction)
            self.transactions.append(managedObject)
            return managedObject.uuid
        }
        
    }
    
    func getFinancialTransactions(userID: String) -> [CashFlow] {
        return cashQueue.sync {
            self.transactions.filter{ $0.playerID == userID }.sorted { $0.id > $1.id }.map{ CashFlow($0)}
        }
    }
    
    @discardableResult
    func create(_ land: Land) -> String {
        return landQueue.sync(flags: .barrier) {
            let managedObject = LandManagedObject(land)
            self.lands.append(managedObject)
            return managedObject.uuid
        }
        
    }
    
    func find(address: MapPoint) -> Land? {
        return landQueue.sync {
            self.lands.first{ $0.x == address.x && $0.y == address.y }.map { Land($0) }
        }
    }
    
    func getAll() -> [Land] {
        return landQueue.sync {
            self.lands.map { Land($0) }
        }
    }
    
    func removeLand(uuid: String) {
        landQueue.sync(flags: .barrier) {
            self.lands.removeAll{ $0.uuid == uuid }
        }
    }
    
    
    func update(_ mutation: LandMutation) {
        landQueue.sync(flags: .barrier) {
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
    
    
    @discardableResult
    func create(_ road: Road) -> String {
        return roadQueue.sync(flags: .barrier) {
            let managedObject = RoadManagedObject(road)
            self.roads.append(managedObject)
            return managedObject.uuid
        }
    }
    
    func find(address: MapPoint) -> Road? {
        return roadQueue.sync {
            self.roads.first{ $0.x == address.x && $0.y == address.y }.map { Road($0) }
        }
    }
    
    func getAll() -> [Road] {
        return roadQueue.sync {
            self.roads.map { Road($0) }
        }
    }
    
    func getUnderConstruction() -> [Road] {
        return roadQueue.sync {
            self.roads.filter{ $0.isUnderConstruction }.map { Road($0) }
        }
    }
    
    func removeRoad(uuid: String) {
        roadQueue.sync(flags: .barrier) {
            self.roads.removeAll{ $0.uuid == uuid }
        }
    }
    
    
    func update(_ mutation: RoadMutation) {
        roadQueue.sync(flags: .barrier) {
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

    @discardableResult
    func create(_ building: ResidentialBuilding) -> String {
        return residentialBuildingQueue.sync(flags: .barrier) {
            let managedObject = ResidentialBuildingManagedObject(building)
            self.buildings.append(managedObject)
            return managedObject.uuid
        }
    }
    
    func find(address: MapPoint) -> ResidentialBuilding? {
        return residentialBuildingQueue.sync {
            return self.buildings.first{ $0.x == address.x && $0.y == address.y }.map { ResidentialBuilding($0) }
        }
    }
    
    func getAll() -> [ResidentialBuilding] {
        return residentialBuildingQueue.sync {
            self.buildings.map { ResidentialBuilding($0) }
        }
    }
    
    func getUnderConstruction() -> [ResidentialBuilding] {
        return residentialBuildingQueue.sync {
            self.buildings.filter{ $0.isUnderConstruction }.map { ResidentialBuilding($0) }
        }
    }
    
    func removeResidentialBuilding(uuid: String) {
        residentialBuildingQueue.sync(flags: .barrier) {
            self.buildings.removeAll{ $0.uuid == uuid }
        }
    }
    
    
    func update(_ mutation: ResidentialBuildingMutation) {
        residentialBuildingQueue.sync(flags: .barrier) {
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
    
    
    @discardableResult
    func create(_ advert: SaleAdvert) -> String {
        return queue.sync(flags: .barrier) {
            let managedObject = SaleAdvertManagedObject(advert)
            self.adverts.append(managedObject)
            return managedObject.uuid
        }
    }
    
    func find(address: MapPoint) -> SaleAdvert? {
        return queue.sync {
            return self.adverts.first{ $0.x == address.x && $0.y == address.y }.map{ SaleAdvert($0) }
        }
    }
    
    func getAll() -> [SaleAdvert] {
        return queue.sync {
            self.adverts.map { SaleAdvert($0) }
        }
    }
    
    
    func update(_ mutation: SaleAdvertMutation) {
        queue.sync(flags: .barrier) {
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
        queue.sync(flags: .barrier) {
            self.adverts.removeAll{ $0.x == address.x && $0.y == address.y }
        }
    }
    
    
    func create(_ register: PropertyRegister) -> String {
        return propertyQueue.sync(flags: .barrier) {
            let managedObject = PropertyRegisterManagedObject(register)
            self.register.append(managedObject)
            return managedObject.uuid
        }
    }
    
    func find(uuid: String) -> PropertyRegister? {
        return propertyQueue.sync {
            return self.register.first{ $0.uuid == uuid }.map{ PropertyRegister($0) }
        }
    }
    
    func get(playerUUID: String) -> [PropertyRegister] {
        return propertyQueue.sync {
            return self.register.filter{ $0.playerUUID == playerUUID }.map{ PropertyRegister($0) }
        }
    }
    
    func update(_ mutation: PropertyRegisterMutation) {
        propertyQueue.sync(flags: .barrier) {
            guard let managedObject = (self.register.first{ $0.uuid == mutation.uuid }) else { return }
            for attribute in mutation.attributes {
                switch attribute {
                case .playerUUID(let value):
                    managedObject.playerUUID = value
                case .type(let value):
                    managedObject.type = value
                }
            }
        }
    }
    
    func removePropertyRegister(uuid: String) {
        propertyQueue.sync(flags: .barrier) {
            self.register.removeAll{ $0.uuid == uuid }
        }
    }
}
