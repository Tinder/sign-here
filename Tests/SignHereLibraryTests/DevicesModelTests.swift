//
//  DevicesModelTests.swift
//  SignHereLibraryTests
//
//  Created by Caleb Davis on 06/21/2023.
//

@testable import SignHereLibrary
import XCTest

final class DevicesModelTests: XCTestCase {
    func testPlatform_rawValue() {
        XCTAssertEqual(Platform.iOS.rawValue, "IOS")
        XCTAssertEqual(Platform.macOS.rawValue, "MAC_OS")
    }

    func testStatus_rawValue() {
        XCTAssertEqual(Status.enabled.rawValue, "ENABLED")
        XCTAssertEqual(Status.disabled.rawValue, "DISABLED")
    }
}
