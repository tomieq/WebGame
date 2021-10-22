//
//  DataStoreProvider.swift
//  
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation

protocol DataStoreProvider {
    @discardableResult func create(_ player: Player) -> String
    @discardableResult func create(_ transaction: CashFlow) -> String
    @discardableResult func create(_ transaction: Land) -> String
    @discardableResult func create(_ transaction: Road) -> String
    @discardableResult func create(_ transaction: ResidentialBuilding) -> String
    @discardableResult func create(_ advert: SaleAdvert) -> String
    
    func find(uuid: String) -> Player?
    func find(address: MapPoint) -> Land?
    func find(address: MapPoint) -> Road?
    func find(address: MapPoint) -> ResidentialBuilding?
    func find(address: MapPoint) -> SaleAdvert?
    func getFinancialTransactions(userID: String) -> [CashFlow]
    
    func getAll() -> [Land]
    func getAll() -> [Road]
    func getAll() -> [ResidentialBuilding]
    func getAll() -> [SaleAdvert]
    
    func getUnderConstruction() -> [Road]
    func getUnderConstruction() -> [ResidentialBuilding]
    
    func update(_ mutation: PlayerMutation)
    func update(_ mutation: LandMutation)
    func update(_ mutation: RoadMutation)
    func update(_ mutation: ResidentialBuildingMutation)

    func removePlayer(id: String)
    func removeLand(uuid: String)
    func removeRoad(uuid: String)
    func removeResidentialBuilding(uuid: String)
    func removeSaleAdvert(address: MapPoint)
}
