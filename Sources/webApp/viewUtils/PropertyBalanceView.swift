//
//  PropertyBalanceView.swift
//  
//
//  Created by Tomasz Kucharski on 05/11/2021.
//

import Foundation

class PropertyBalanceView {
    private var data: [String: String] = [:]
    private var costs: [Invoice] = []
    private var income: [MonthlyIncome] = []
    private var constructionFinishDate: GameTime?
    
    @discardableResult
    func setProperty(_ property: Property) -> PropertyBalanceView {
        if property.isUnderConstruction {
            self.data["type"] = "\(property.type) - under construction"
            self.constructionFinishDate = GameTime(property.constructionFinishMonth)
        } else {
            self.data["type"] = property.type
        }
        self.data["name"] = property.name
        return self
    }
    
    @discardableResult
    func setMonthlyCosts(_ costs: [Invoice]) -> PropertyBalanceView {
        self.costs = costs
        return self
    }
    
    @discardableResult
    func setMonthlyIncome(_ income: [MonthlyIncome]) -> PropertyBalanceView {
        self.income = income
        return self
    }
    
    func output() -> String {
        let template = Template(raw: ResourceCache.shared.getAppResource("templates/propertyManager/balanceView.html"))
        template.assign(variables: self.data)
        
        for cost in self.costs {
            var data: [String:String] = [:]
            data["name"] = cost.title
            data["netValue"] = cost.netValue.money
            data["taxRate"] = (cost.taxRate * 100).rounded(toPlaces: 0).string
            data["taxValue"] = cost.tax.money
            data["total"] = cost.total.money
            template.assign(variables: data, inNest: "cost")
        }
        let totalCosts = self.costs.map{$0.total}.reduce(0, +)
        var costData: [String:String] = [:]
        costData["netValue"] = self.costs.map{$0.netValue}.reduce(0, +).money
        costData["taxValue"] = self.costs.map{$0.tax}.reduce(0, +).money
        costData["total"] = totalCosts.money
        template.assign(variables: costData, inNest: "costTotal")
        
        for income in self.income {
            var data: [String:String] = [:]
            data["name"] = income.name
            data["netValue"] = income.netValue.money
            template.assign(variables: data, inNest: "income")
        }
        
        let balance = (-1 * totalCosts) + self.income.map{$0.netValue}.reduce(0, +)
        var incomeData: [String:String] = [:]
        incomeData["name"] = "Costs"
        incomeData["netValue"] = (-1 * totalCosts).money
        template.assign(variables: incomeData, inNest: "income")
        incomeData = [:]
        incomeData["netValue"] = balance.money
        template.assign(variables: incomeData, inNest: "incomeTotal")
        
        if let date = self.constructionFinishDate {
            template.assign(variables: ["date": date.text], inNest: "underConstruction")
        }
        return template.output()
    }
}
