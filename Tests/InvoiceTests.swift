//
//  InvoiceTests.swift
//
//
//  Created by Tomasz Kucharski on 15/10/2021.
//

import Foundation
import XCTest
@testable import WebGameLib

final class InvoiceTests: XCTestCase {
    func test_invoiceTitle() {
        let invoice = Invoice(title: "Sample title", grossValue: 0, taxRate: 0)
        XCTAssertEqual(invoice.title, "Sample title")
    }

    func test_invoiceEmptyTitle() {
        let invoice = Invoice(title: "", grossValue: 0, taxRate: 0)
        XCTAssertEqual(invoice.title, "")
    }

    func test_netInitializer() {
        let invoice = Invoice(title: "", netValue: 100, taxRate: 0.2)
        XCTAssertEqual(invoice.taxRate, 0.2)
        XCTAssertEqual(invoice.netValue, 100)
        XCTAssertEqual(invoice.tax, 20)
        XCTAssertEqual(invoice.total, 120)
    }

    func test_grossInitializer() {
        let invoice = Invoice(title: "", grossValue: 100, taxRate: 0.2)
        XCTAssertEqual(invoice.taxRate, 0.2)
        XCTAssertEqual(invoice.total, 100)
        XCTAssertEqual(invoice.tax, 17)
        XCTAssertEqual(invoice.netValue, 83)
    }

    func test_netInitializer_zeroTax() {
        let invoice = Invoice(title: "", netValue: 100, taxRate: 0)
        XCTAssertEqual(invoice.taxRate, 0)
        XCTAssertEqual(invoice.total, 100)
        XCTAssertEqual(invoice.tax, 0)
        XCTAssertEqual(invoice.netValue, 100)
    }

    func test_grossInitializer_zeroTax() {
        let invoice = Invoice(title: "", grossValue: 100, taxRate: 0)
        XCTAssertEqual(invoice.taxRate, 0)
        XCTAssertEqual(invoice.total, 100)
        XCTAssertEqual(invoice.tax, 0)
        XCTAssertEqual(invoice.netValue, 100)
    }

    func test_netInitializer_zeroValue() {
        let invoice = Invoice(title: "", netValue: 0, taxRate: 0.5)
        XCTAssertEqual(invoice.taxRate, 0.5)
        XCTAssertEqual(invoice.total, 0)
        XCTAssertEqual(invoice.tax, 0)
        XCTAssertEqual(invoice.netValue, 0)
    }

    func test_grossInitializer_zeroValue() {
        let invoice = Invoice(title: "", grossValue: 0, taxRate: 0.5)
        XCTAssertEqual(invoice.taxRate, 0.5)
        XCTAssertEqual(invoice.total, 0)
        XCTAssertEqual(invoice.tax, 0)
        XCTAssertEqual(invoice.netValue, 0)
    }
}
