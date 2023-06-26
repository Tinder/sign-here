//
//  StoreTests.swift
//  SignHereLibraryTests
//
//  Created by Caleb Davis on 06/21/2023.
//

@testable import SignHereLibrary
import XCTest

final class StoreTests: XCTestCase {
    func testStore_rawValue() {
        XCTAssertEqual(Store.iOSAppStore.rawValue, "IOS_APP_STORE")
        XCTAssertEqual(Store.macAppStore.rawValue, "MAC_APP_STORE")
        XCTAssertEqual(Store.tvAppStore.rawValue, "TVOS_APP_STORE")
        XCTAssertEqual(Store.macCatalystAppStore.rawValue, "MAC_CATALYST_APP_STORE")
    }
}
