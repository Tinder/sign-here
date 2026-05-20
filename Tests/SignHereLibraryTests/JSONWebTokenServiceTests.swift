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

    func test_createToken_enterprise_setsEnterpriseAudienceClaim() throws {
        let token: String = try subject.createToken(
            keyIdentifier: "keyIdentifier",
            issuerID: "issuerID",
            secretKey: Data("""
            -----BEGIN PRIVATE KEY-----
            MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgYYbAldEbugmxcjBB
            QVFTUiVeHTUJDZLi0mXpmE8cfKOgCgYIKoZIzj0DAQehRANCAASxWtei3s6e20fS
            YftL55PhJATjQMDh+Yyx/FCESEM+bUeBoo/4tIggtTESWxJWvIYOwVXylhBukYc1
            Pr+l6ipm
            -----END PRIVATE KEY-----
            """.utf8),
            enterprise: true
        )
        // The payload is the second `.`-separated segment of the JWT.
        let parts: [Substring] = token.split(separator: ".")
        XCTAssertEqual(parts.count, 3)
        let payloadSegment: String = String(parts[1])
        let padded: String = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .padding(
                toLength: payloadSegment.count + (4 - payloadSegment.count % 4) % 4,
                withPad: "=",
                startingAt: 0
            )
        guard let decoded: Data = Data(base64Encoded: padded) else {
            return XCTFail("payload segment was not base64-decodable")
        }
        let payloadString: String = String(decoding: decoded, as: UTF8.self)
        XCTAssertTrue(
            payloadString.contains("apple-developer-enterprise-v1"),
            "enterprise=true should produce an `aud` claim of `apple-developer-enterprise-v1`, got: \(payloadString)"
        )
    }

    func test_createToken_throwsWhenSecretKeyIsNotValidUTF8() {
        // 0xFF, 0xFE form an invalid UTF-8 sequence so String(data:encoding:.utf8)
        // returns nil and createSignature throws .unableToCreateKeyString.
        XCTAssertThrowsError(
            try subject.createToken(
                keyIdentifier: "k",
                issuerID: "i",
                secretKey: Data([0xFF, 0xFE]),
                enterprise: false
            )
        ) { error in
            guard case JSONWebTokenServiceImp.Error.unableToCreateKeyString = error else {
                XCTFail("expected .unableToCreateKeyString, got \(error)")
                return
            }
            XCTAssertEqual(
                "\(error)",
                "[JSONWebTokenService] Unable to create key string"
            )
        }
    }

    func test_createToken_throwsWhenSecretKeyIsNotAValidPEM() {
        XCTAssertThrowsError(
            try subject.createToken(
                keyIdentifier: "k",
                issuerID: "i",
                secretKey: Data("definitely not a PEM".utf8),
                enterprise: false
            )
        )
    }

    func test_errorDescriptions_haveStableText() {
        XCTAssertEqual(
            "\(JSONWebTokenServiceImp.Error.unableToCreateKeyString)",
            "[JSONWebTokenService] Unable to create key string"
        )
        XCTAssertEqual(
            "\(JSONWebTokenServiceImp.Error.unableToCreatePrivateKey)",
            "[JSONWebTokenService] Unable to create private key"
        )
    }
}
