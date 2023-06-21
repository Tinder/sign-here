//
//  PlatformTests.swift
//  SignHereLibraryTests
//
//  Created by Caleb Davis on 06/21/2023.
//

@testable import SignHereLibrary
import XCTest

final class PlatformTests: XCTestCase {
    func test_rawValue() {
        XCTAssertEqual(Platform.iOS.rawValue, "IOS")
        XCTAssertEqual(Platform.macOS.rawValue, "MAC_OS")
    }
}
