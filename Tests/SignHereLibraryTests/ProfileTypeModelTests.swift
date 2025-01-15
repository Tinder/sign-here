//
//  CreateProvisioningProfileCommandTests.swift
//  SignHereLibraryTests
//
//  Created by Omar Zuniga on 29/05/24.
//

import ArgumentParser
import CoreLibrary
import CoreLibrary_GeneratedMocks
import CoreLibraryTestKit
import PathKit
import XCTest

@testable import SignHereLibrary
@testable import SignHereLibrary_GeneratedMocks

final class ProfileTypeModelTests: XCTestCase {

    func testDevelopmentType() {
        // GIVEN
        let prefixes = [
            "IOS",
            "MAC",
            "TVOS",
            "MAC_CATALYST"
        ]
        let suffix = "_APP_DEVELOPMENT"
        // WHEN
        let profileTypes = prefixes.map {
            ProfileType(rawValue: "\($0)\(suffix)")
        }
        // THEN
        profileTypes.forEach { profileType in
            XCTAssertEqual(profileType, .development)
            XCTAssertEqual(profileType.usesDevices, true)
        }
    }

    func testAdHocType() {
        // GIVEN
        let prefixes = [
            "IOS",
            "TVOS"
        ]
        let suffix = "_APP_ADHOC"
        // WHEN
        let profileTypes = prefixes.map {
            ProfileType(rawValue: "\($0)\(suffix)")
        }
        // THEN
        profileTypes.forEach { profileType in
            XCTAssertEqual(profileType, .adHoc)
            XCTAssertEqual(profileType.usesDevices, true)
        }
    }

    func testAppStoreType() {
        // GIVEN
        let prefixes = [
            "IOS",
            "MAC",
            "TVOS",
            "MAC_CATALYST"
        ]
        let suffix = "_APP_STORE"
        // WHEN
        let profileTypes = prefixes.map {
            ProfileType(rawValue: "\($0)\(suffix)")
        }
        // THEN
        profileTypes.forEach { profileType in
            XCTAssertEqual(profileType, .appStore)
            XCTAssertEqual(profileType.usesDevices, false)
        }
    }


    func testInHouseType() {
        // GIVEN
        let prefixes = [
            "IOS",
            "TVOS"
        ]
        let suffix = "_APP_INHOUSE"
        // WHEN
        let profileTypes = prefixes.map {
            ProfileType(rawValue: "\($0)\(suffix)")
        }
        // THEN
        profileTypes.forEach { profileType in
            XCTAssertEqual(profileType, .inHouse)
            XCTAssertEqual(profileType.usesDevices, false)
        }
    }

    func testDirectType() {
        // GIVEN
        let prefixes = [
            "MAC",
            "MAC_CATALYST"
        ]
        let suffix = "_APP_DIRECT"
        // WHEN
        let profileTypes = prefixes.map {
            ProfileType(rawValue: "\($0)\(suffix)")
        }
        // THEN
        profileTypes.forEach { profileType in
            XCTAssertEqual(profileType, .direct)
            XCTAssertEqual(profileType.usesDevices, true)
        }
    }
}
