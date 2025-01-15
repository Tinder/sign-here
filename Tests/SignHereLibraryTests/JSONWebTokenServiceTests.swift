//
//  JSONWebTokenServiceTests.swift
//  SignHereLibraryTests
//
//  Created by Maxwell Elliott on 03/28/23.
//

import CoreLibrary_GeneratedMocks
import CoreLibraryTestKit
@testable import SignHereLibrary
import XCTest

final class JSONWebTokenServiceTests: XCTestCase {
    var clock: ClockMock!
    var subject: JSONWebTokenService!

    override func setUp() {
        super.setUp()
        clock = .init()
        clock.nowHandler = {
            Date(timeIntervalSince1970: 0)
        }
        subject = JSONWebTokenServiceImp(clock: clock)
    }

    override func tearDown() {
        clock = nil
        subject = nil
        super.tearDown()
    }

    func test_init() {
        XCTAssertNotNil(JSONWebTokenServiceImp(clock: clock))
    }

    func test_createToken() throws {
        XCTAssertNotNil(
            try subject.createToken(
                keyIdentifier: "keyIdentifier",
                issuerID: "issuerID",
                // ME: This is not a real key
                secretKey: Data("""
                -----BEGIN PRIVATE KEY-----
                MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgYYbAldEbugmxcjBB
                QVFTUiVeHTUJDZLi0mXpmE8cfKOgCgYIKoZIzj0DAQehRANCAASxWtei3s6e20fS
                YftL55PhJATjQMDh+Yyx/FCESEM+bUeBoo/4tIggtTESWxJWvIYOwVXylhBukYc1
                Pr+l6ipm
                -----END PRIVATE KEY-----
                """.utf8),
                enterprise: false
            )
        )
    }
}
