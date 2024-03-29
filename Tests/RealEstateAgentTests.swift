//
//  RealEstateAgentTests.swift
//
//
//  Created by Tomasz Kucharski on 16/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class RealEstateAgentTests: XCTestCase {
    func test_registerOffer_outsideMap() {
        let agent = self.makeAgent()

        XCTAssertThrowsError(try agent.registerSaleOffer(address: MapPoint(x: 30, y: 30), netValue: 3000)) { error in
            XCTAssertEqual(error as? RegisterOfferError, .propertyDoesNotExist)
        }
    }

    func test_registerOffer_nonExistingProperty() {
        let agent = self.makeAgent()

        XCTAssertThrowsError(try agent.registerSaleOffer(address: MapPoint(x: 5, y: 5), netValue: 3000)) { error in
            XCTAssertEqual(error as? RegisterOfferError, .propertyDoesNotExist)
        }
    }

    func test_registerOffer_twice() {
        let agent = self.makeAgent()

        let address = MapPoint(x: 5, y: 3)
        let land = Land(address: address, ownerUUID: "john")
        agent.dataStore.create(land)
        agent.mapManager.map.setTiles([GameMapTile(address: address, type: .soldLand)])

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 3000))
        XCTAssertThrowsError(try agent.registerSaleOffer(address: address, netValue: 3000)) { error in
            XCTAssertEqual(error as? RegisterOfferError, .advertAlreadyExists)
        }
    }

    func test_registerLandOffer_propertyBlockedByDebtCollector() {
        let agent = self.makeAgent()

        let address = MapPoint(x: 5, y: 3)
        let land = Land(address: address, ownerUUID: "john")
        let landUUID = agent.dataStore.create(land)
        agent.mapManager.map.setTiles([GameMapTile(address: address, type: .soldLand)])
        let register = PropertyRegister(uuid: landUUID, address: land.address, playerUUID: "john", type: .land)
        agent.dataStore.create(register)
        let mutation = PropertyRegisterMutation(uuid: landUUID, attributes: [.status(.blockedByDebtCollector)])
        agent.dataStore.update(mutation)

        XCTAssertThrowsError(try agent.registerSaleOffer(address: address, netValue: 3000)) { error in
            XCTAssertEqual(error as? RegisterOfferError, .propertyBlockedByDebtCollector)
        }
    }

    func test_registerLandOffer_advertExists() {
        let agent = self.makeAgent()

        let address = MapPoint(x: 5, y: 3)
        let land = Land(address: address, ownerUUID: "john")
        agent.dataStore.create(land)
        agent.mapManager.map.setTiles([GameMapTile(address: address, type: .soldLand)])

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 3000))
        let advert: SaleAdvert? = agent.dataStore.find(address: address)
        XCTAssertNotNil(advert)
        XCTAssertEqual(advert?.netPrice, 3000)
        XCTAssertEqual(advert?.address, address)
    }

    func test_registerLandOffer_properOfferNetValue() {
        let agent = self.makeAgent()

        let address = MapPoint(x: 5, y: 5)
        let land = Land(address: address, ownerUUID: "john")
        agent.dataStore.create(land)
        agent.mapManager.map.setTiles([GameMapTile(address: address, type: .soldLand)])

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 3000))
        let offer = agent.saleOffer(address: address, buyerUUID: "buyer")
        XCTAssertNotNil(offer)
        XCTAssertEqual(offer?.saleInvoice.netValue, 3000)
    }

    func test_updateSaleOffer_advertDoesNotExist() {
        let agent = self.makeAgent()
        agent.centralBank.taxRates.incomeTax = 0.1

        let address = MapPoint(x: 3, y: 3)
        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 3000)
        agent.dataStore.create(buyer)
        let land = Land(address: address, ownerUUID: "seller", purchaseNetValue: 600)
        agent.dataStore.create(land)
        agent.mapManager.addPrivateLand(address: address)

        XCTAssertThrowsError(try agent.updateSaleOffer(address: address, netValue: 2500)) { error in
            XCTAssertEqual(error as? UpdateOfferError, .offerDoesNotExist)
        }
    }

    func test_updateSaleOffer() {
        let agent = self.makeAgent()
        agent.centralBank.taxRates.incomeTax = 0.1

        let address = MapPoint(x: 3, y: 3)
        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 3000)
        agent.dataStore.create(buyer)
        let land = Land(address: address, ownerUUID: "seller", purchaseNetValue: 600)
        agent.dataStore.create(land)
        agent.mapManager.addPrivateLand(address: address)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 2000))
        XCTAssertNoThrow(try agent.updateSaleOffer(address: address, netValue: 2500))

        let offer = agent.saleOffer(address: address, buyerUUID: "buyer")
        XCTAssertNotNil(offer)
        XCTAssertEqual(offer?.saleInvoice.netValue, 2500)
    }

    func test_landSaleOffer_notForSale() {
        let agent = self.makeAgent()
        let address = MapPoint(x: 3, y: 3)
        let land = Land(address: address, ownerUUID: "john")
        agent.dataStore.create(land)
        agent.mapManager.map.setTiles([GameMapTile(address: address, type: .soldLand)])

        XCTAssertNil(agent.saleOffer(address: address, buyerUUID: "random"))
    }

    func test_landSaleOffer_fromGovernment_properOffer() {
        let agent = self.makeAgent()

        let offer = agent.saleOffer(address: MapPoint(x: 3, y: 3), buyerUUID: "random")
        XCTAssertNotNil(offer)
    }

    func test_buyLandProperty_fromGovernment_notEnoughMoney() {
        let agent = self.makeAgent()
        agent.propertyValuer.valueFactors.baseLandValue = 5000

        let player = Player(uuid: "buyer", login: "tester", wallet: 100)
        agent.dataStore.create(player)

        let address = MapPoint(x: 3, y: 3)
        XCTAssertThrowsError(try agent.buyProperty(address: address, buyerUUID: "buyer")) { error in
            XCTAssertEqual(error as? BuyPropertyError, .financialTransactionProblem(.notEnoughMoney))
        }
    }

    func test_buyLandProperty_ownSaleOffer() {
        let agent = self.makeAgent()

        let address = MapPoint(x: 3, y: 3)
        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let land = Land(address: address, ownerUUID: "seller", purchaseNetValue: 100)
        agent.dataStore.create(land)
        agent.mapManager.addPrivateLand(address: address)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 660))
        XCTAssertThrowsError(try agent.buyProperty(address: address, buyerUUID: "seller")) { error in
            XCTAssertEqual(error as? BuyPropertyError, .tryingBuyOwnProperty)
        }
    }

    func test_buyLandProperty_offerPriceMismatch() {
        let agent = self.makeAgent()

        let address = MapPoint(x: 3, y: 3)
        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let land = Land(address: address, ownerUUID: "seller", purchaseNetValue: 100)
        agent.dataStore.create(land)
        agent.mapManager.addPrivateLand(address: address)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 660))
        XCTAssertThrowsError(try agent.buyProperty(address: address, buyerUUID: "seller", netPrice: 680)) { error in
            XCTAssertEqual(error as? BuyPropertyError, .saleOfferHasChanged)
        }
        let notSoldLand: Land? = agent.dataStore.find(address: address)
        XCTAssertEqual(notSoldLand?.ownerUUID, "seller")
    }

    func test_buyLandProperty_fromGovernment_success() {
        let agent = self.makeAgent()
        agent.propertyValuer.valueFactors.baseLandValue = 400

        let address = MapPoint(x: 3, y: 3)
        let player = Player(uuid: "buyer", login: "tester", wallet: 1000)
        agent.dataStore.create(player)

        XCTAssertNoThrow(try agent.buyProperty(address: address, buyerUUID: player.uuid))

        let land: Land? = agent.dataStore.find(address: address)
        XCTAssertEqual(land?.ownerUUID, player.uuid)
        let register: PropertyRegister? = agent.dataStore.find(uuid: land?.uuid ?? "")
        XCTAssertNotNil(register)
        XCTAssertEqual(register?.ownerUUID, player.uuid)
        XCTAssertEqual(land?.uuid, register?.uuid)
        let registers: [PropertyRegister] = agent.dataStore.get(ownerUUID: "buyer")
        XCTAssertEqual(registers.count, 1)
    }

    func test_buyLandProperty_fromOtherUser_success() {
        let agent = self.makeAgent()

        let address = MapPoint(x: 3, y: 3)
        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 1000)
        agent.dataStore.create(buyer)
        let land = Land(address: address, ownerUUID: seller.uuid, purchaseNetValue: 100)
        let landUUID = agent.dataStore.create(land)
        let register = PropertyRegister(uuid: landUUID, address: land.address, playerUUID: seller.uuid, type: .land)
        agent.dataStore.create(register)
        agent.mapManager.addPrivateLand(address: address)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 660))
        XCTAssertNoThrow(try agent.buyProperty(address: address, buyerUUID: "buyer"))

        let soldLand: Land? = agent.dataStore.find(address: address)
        XCTAssertEqual(soldLand?.ownerUUID, "buyer")
        XCTAssertEqual(soldLand?.purchaseNetValue, 660)
        let soldRegister: PropertyRegister? = agent.dataStore.find(uuid: landUUID)
        XCTAssertNotNil(soldRegister)
        XCTAssertEqual(soldRegister?.ownerUUID, buyer.uuid)
    }

    func test_buyLandProperty_fromOtherUser_incomeTaxRefund() {
        let agent = self.makeAgent()
        agent.centralBank.taxRates.incomeTax = 0.1

        let address = MapPoint(x: 3, y: 3)
        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 3000)
        agent.dataStore.create(buyer)
        let land = Land(address: address, ownerUUID: "seller", purchaseNetValue: 600, investmentsNetValue: 400)
        agent.dataStore.create(land)
        agent.mapManager.addPrivateLand(address: address)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 2000))
        XCTAssertNoThrow(try agent.buyProperty(address: address, buyerUUID: "buyer"))

        let updatedSeller: Player? = agent.dataStore.find(uuid: "seller")
        XCTAssertEqual(updatedSeller?.wallet, 1900)
    }

    func test_buyLandProperty_fromOtherUser_advertDeleted() {
        let agent = self.makeAgent()
        agent.centralBank.taxRates.incomeTax = 0.1

        let address = MapPoint(x: 3, y: 3)
        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 3000)
        agent.dataStore.create(buyer)
        let land = Land(address: address, ownerUUID: "seller", purchaseNetValue: 600)
        let landID = agent.dataStore.create(land)
        agent.mapManager.addPrivateLand(address: address)

        agent.dataStore.update(LandMutation(uuid: landID, attributes: [.investments(400)]))

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 2000))
        XCTAssertNoThrow(try agent.buyProperty(address: address, buyerUUID: "buyer"))

        XCTAssertNil(agent.saleOffer(address: address, buyerUUID: "buyer"))
    }

    func test_residentialBuildingSaleOffer_notForSale() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")

        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "somebody"), storeyAmount: 4)
        agent.dataStore.create(building)

        XCTAssertEqual(agent.mapManager.map.getTile(address: address)?.isBuilding(), true)
        XCTAssertNil(agent.saleOffer(address: address, buyerUUID: "random"))
    }

    func test_residentialBuildingSaleOffer_fromGovernment_properOffer() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")

        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address), storeyAmount: 4)
        agent.dataStore.create(building)

        XCTAssertNotNil(agent.saleOffer(address: address, buyerUUID: "random"))
    }

    func test_registerResidentialBuildingOffer_advertExists() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")
        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "seller"), storeyAmount: 4)
        agent.dataStore.create(building)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 900))
        let advert: SaleAdvert? = agent.dataStore.find(address: address)
        XCTAssertNotNil(advert)
        XCTAssertEqual(advert?.netPrice, 900)
    }

    func test_buyResidentialBuilding_fromGovernment_notEnoughMoney() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")
        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address), storeyAmount: 4)
        agent.dataStore.create(building)

        let player = Player(uuid: "buyer", login: "tester", wallet: 0)
        agent.dataStore.create(player)

        XCTAssertThrowsError(try agent.buyProperty(address: address, buyerUUID: "buyer")) { error in
            XCTAssertEqual(error as? BuyPropertyError, .financialTransactionProblem(.notEnoughMoney))
        }
    }

    func test_buyResidentialBuilding_fromGovernment() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")
        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address), storeyAmount: 4)
        let buildingUUID = agent.dataStore.create(building)

        let player = Player(uuid: "buyer", login: "tester", wallet: 10000000)
        agent.dataStore.create(player)

        let offer = agent.saleOffer(address: address, buyerUUID: "buyer")
        XCTAssertNoThrow(try agent.buyProperty(address: address, buyerUUID: "buyer"))

        let soldBuilding: ResidentialBuilding? = agent.dataStore.find(address: address)
        XCTAssertEqual(soldBuilding?.ownerUUID, "buyer")
        XCTAssertEqual(soldBuilding?.investmentsNetValue, offer?.commissionInvoice.total)
        let register: PropertyRegister? = agent.dataStore.find(uuid: buildingUUID)
        XCTAssertNotNil(register)
        XCTAssertEqual(register?.ownerUUID, player.uuid)
    }

    func test_buyResidentialBuilding_fromOtherUser_offerPriceMismatch() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")

        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "seller", purchaseNetValue: 200), storeyAmount: 4)
        agent.dataStore.create(building)

        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 100000)
        agent.dataStore.create(buyer)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 887))
        XCTAssertThrowsError(try agent.buyProperty(address: address, buyerUUID: "buyer", netPrice: 888)) { error in
            XCTAssertEqual(error as? BuyPropertyError, .saleOfferHasChanged)
        }
        let notSoldBuilding: ResidentialBuilding? = agent.dataStore.find(address: address)
        XCTAssertEqual(notSoldBuilding?.ownerUUID, "seller")
    }

    func test_buyResidentialBuilding_fromOtherUser() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")

        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 100000)
        agent.dataStore.create(buyer)

        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "seller", purchaseNetValue: 200), storeyAmount: 4)
        let buildingUUID = agent.dataStore.create(building)
        let register = PropertyRegister(uuid: buildingUUID, address: address, playerUUID: seller.uuid, type: .residentialBuilding)
        agent.dataStore.create(register)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 887))
        let offer = agent.saleOffer(address: address, buyerUUID: "buyer")
        XCTAssertNoThrow(try agent.buyProperty(address: address, buyerUUID: "buyer"))

        let soldBuilding: ResidentialBuilding? = agent.dataStore.find(address: address)
        XCTAssertEqual(soldBuilding?.ownerUUID, "buyer")
        XCTAssertEqual(soldBuilding?.purchaseNetValue, 887)
        XCTAssertEqual(soldBuilding?.investmentsNetValue, offer?.commissionInvoice.total)
        let updatedRegister: PropertyRegister? = agent.dataStore.find(uuid: buildingUUID)
        XCTAssertEqual(updatedRegister?.ownerUUID, buyer.uuid)
    }

    func test_buyResidentialBuilding_fromOtherUser_advertDeleted() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")

        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "seller", purchaseNetValue: 200), storeyAmount: 4)
        agent.dataStore.create(building)

        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)
        let buyer = Player(uuid: "buyer", login: "buyer", wallet: 100000)
        agent.dataStore.create(buyer)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 887))
        XCTAssertNoThrow(try agent.buyProperty(address: address, buyerUUID: "buyer"))
        XCTAssertNil(agent.saleOffer(address: address, buyerUUID: "buyer"))
    }

    func test_buyResidentialBuilding_ownSaleOffer() {
        let agent = self.makeAgent()
        agent.mapManager.loadMapFrom(content: "b")

        let address = MapPoint(x: 0, y: 0)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "seller", purchaseNetValue: 200), storeyAmount: 4)
        agent.dataStore.create(building)

        let seller = Player(uuid: "seller", login: "seller", wallet: 0)
        agent.dataStore.create(seller)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 887))
        XCTAssertThrowsError(try agent.buyProperty(address: address, buyerUUID: "seller")) { error in
            XCTAssertEqual(error as? BuyPropertyError, .tryingBuyOwnProperty)
        }
    }

    func test_getAllRegisteredLandSaleOffers() {
        let agent = self.makeAgent()

        for i in (1...5) {
            let address = MapPoint(x: i, y: i)
            let land = Land(address: address, ownerUUID: "john")
            agent.dataStore.create(land)
            agent.mapManager.addPrivateLand(address: address)
            XCTAssertEqual(agent.mapManager.map.getTile(address: address)?.propertyType, .land)
            XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 3000))
        }
        let offers = agent.getAllSaleOffers(buyerUUID: "buyer")
        XCTAssertEqual(offers.count, 5)
        let offerAddresses = offers.map{ $0.property.address }
        (1...5).forEach { i in
            let address = MapPoint(x: i, y: i)
            XCTAssertTrue(offerAddresses.contains(address))
        }
    }

    func test_isForSale_unownedLand() {
        let agent = self.makeAgent()
        XCTAssertEqual(agent.isForSale(address: MapPoint(x: 1, y: 1)), true)
    }

    func test_isForSale_somebodysLandWithoutAdvert() {
        let agent = self.makeAgent()
        let address = MapPoint(x: 1, y: 1)
        let land = Land(address: address, ownerUUID: "owner")
        agent.dataStore.create(land)
        agent.mapManager.addPrivateLand(address: address)

        XCTAssertEqual(agent.isForSale(address: address), false)
    }

    func test_isForSale_somebodysLandWitAdvert() {
        let agent = self.makeAgent()
        let address = MapPoint(x: 1, y: 1)
        let land = Land(address: address, ownerUUID: "owner")
        agent.dataStore.create(land)
        agent.mapManager.addPrivateLand(address: address)

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 1000))
        XCTAssertEqual(agent.isForSale(address: address), true)
    }

    func test_isForSale_governmentsResidentialBuilding() {
        let agent = self.makeAgent()
        let address = MapPoint(x: 1, y: 1)
        let building = ResidentialBuilding(land: Land(address: address), storeyAmount: 4)
        agent.dataStore.create(building)
        agent.mapManager.loadMapFrom(content: "\n,b,b")

        XCTAssertEqual(agent.isForSale(address: address), true)
    }

    func test_isForSale_somebodysResidentialBuildingWithoutAdvert() {
        let agent = self.makeAgent()
        let address = MapPoint(x: 1, y: 1)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "owner"), storeyAmount: 4)
        agent.dataStore.create(building)
        agent.mapManager.loadMapFrom(content: "\n,b,b")

        XCTAssertEqual(agent.isForSale(address: address), false)
    }

    func test_isForSale_somebodysResidentialBuildingWithAdvert() {
        let agent = self.makeAgent()
        let address = MapPoint(x: 1, y: 1)
        let building = ResidentialBuilding(land: Land(address: address, ownerUUID: "owner"), storeyAmount: 4)
        agent.dataStore.create(building)
        agent.mapManager.loadMapFrom(content: "\n,b,b")

        XCTAssertNoThrow(try agent.registerSaleOffer(address: address, netValue: 10000))

        XCTAssertEqual(agent.isForSale(address: address), true)
    }

    private func makeAgent() -> RealEstateAgent {
        let dataStore = DataStoreMemoryProvider()
        let taxRates = TaxRates()
        let time = GameTime()
        let centralBank = CentralBank(dataStore: dataStore, taxRates: taxRates, time: time)
        let map = GameMap(width: 10, height: 10, scale: 0.2)
        let mapManager = GameMapManager(map)

        let constructionServices = ConstructionServices(mapManager: mapManager, centralBank: centralBank, time: time)
        let parkingClientCalculator = ParkingClientCalculator(mapManager: mapManager, dataStore: dataStore)
        let balanceCalculator = PropertyBalanceCalculator(mapManager: mapManager, parkingClientCalculator: parkingClientCalculator, taxRates: taxRates)
        let propertyValuer = PropertyValuer(balanceCalculator: balanceCalculator, constructionServices: constructionServices)
        let agent = RealEstateAgent(mapManager: mapManager, propertyValuer: propertyValuer, centralBank: centralBank, delegate: nil)

        let government = Player(uuid: SystemPlayer.government.uuid, login: SystemPlayer.government.login, wallet: 0)
        agent.dataStore.create(government)

        let agency = Player(uuid: SystemPlayer.realEstateAgency.uuid, login: SystemPlayer.realEstateAgency.login, wallet: 0)
        agent.dataStore.create(agency)

        return agent
    }
}
