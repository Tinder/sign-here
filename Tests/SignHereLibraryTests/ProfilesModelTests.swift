//
//  ProfilesModelTests.swift
//  SignHereLibraryTests
//
//  Created by Caleb Davis on 06/21/2023.
//

@testable import SignHereLibrary
import XCTest

final class ProfilesModelTests: XCTestCase {
    func testProfileState_rawValue() {
        XCTAssertEqual(ProfileState.active.rawValue, "ACTIVE")
        XCTAssertEqual(ProfileState.invalid.rawValue, "INVALID")
    }

    func testProfileType_rawValue() {
        XCTAssertEqual(ProfileType.iOSAppDevelopment.rawValue, "IOS_APP_DEVELOPMENT")
        XCTAssertEqual(ProfileType.iOSAppStore.rawValue, "IOS_APP_STORE")
        XCTAssertEqual(ProfileType.iOSAppAdhoc.rawValue, "IOS_APP_ADHOC")
        XCTAssertEqual(ProfileType.iOSAppInhouse.rawValue, "IOS_APP_INHOUSE")
        XCTAssertEqual(ProfileType.macAppDevelopment.rawValue, "MAC_APP_DEVELOPMENT")
        XCTAssertEqual(ProfileType.macAppStore.rawValue, "MAC_APP_STORE")
        XCTAssertEqual(ProfileType.macAppDirect.rawValue, "MAC_APP_DIRECT")
        XCTAssertEqual(ProfileType.tvOSAppDevelopment.rawValue, "TVOS_APP_DEVELOPMENT")
        XCTAssertEqual(ProfileType.tvOSAppStore.rawValue, "TVOS_APP_STORE")
        XCTAssertEqual(ProfileType.tvOSAppAdhoc.rawValue, "TVOS_APP_ADHOC")
        XCTAssertEqual(ProfileType.tvOSAppInhouse.rawValue, "TVOS_APP_INHOUSE")
        XCTAssertEqual(ProfileType.macCatalystAppDevelopment.rawValue, "MAC_CATALYST_APP_DEVELOPMENT")
        XCTAssertEqual(ProfileType.macCatalystAppStore.rawValue, "MAC_CATALYST_APP_STORE")
        XCTAssertEqual(ProfileType.macCatalystAppDirect.rawValue, "MAC_CATALYST_APP_DIRECT")
    }

}
