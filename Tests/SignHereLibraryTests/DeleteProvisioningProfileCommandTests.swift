//
//  DeleteProvisioningProfileCommandTests.swift
//  SignHereLibraryTests
//
//  Created by Maxwell Elliott on 04/10/23.
//

import ArgumentParser
import CoreLibrary
import CoreLibrary_GeneratedMocks
import CoreLibraryTestKit
import XCTest

@testable import SignHereLibrary
@testable import SignHereLibrary_GeneratedMocks

final class DeleteProvisioningProfileCommandTests: XCTestCase {
    var files: FilesMock!
    var jsonWebTokenService: JSONWebTokenServiceMock!
    var iTunesConnectService: iTunesConnectServiceMock!
    var subject: DeleteProvisioningProfileCommand!

    override func setUp() {
        super.setUp()
        files = .init()
        jsonWebTokenService = .init()
        iTunesConnectService = .init()
        subject = .init(
            files: files,
            jsonWebTokenService: jsonWebTokenService,
            iTunesConnectService: iTunesConnectService,
            provisioningProfileId: "provisioningProfileId",
            keyIdentifier: "keyIdentifier",
            issuerID: "issuerID",
            itunesConnectKeyPath: "/itunesConnectKeyPath",
            enterprise: false
        )
    }

    func testConfiguration() {
        let configuration: CommandConfiguration = DeleteProvisioningProfileCommand.configuration
        XCTAssertEqual(configuration.commandName, "delete-provisioning-profile")
    }

    func testInit() throws {
        let command: Any = DeleteProvisioningProfileCommand()
        XCTAssertTrue(command is ParsableCommand)
    }

    func testInitDecode() throws {
        // GIVEN
        let data: Data = .init("""
        {
            "provisioningProfileId": "provisioningProfileId",
            "keyIdentifier": "keyIdentifier",
            "issuerID": "issuerID",
            "itunesConnectKeyPath": "/itunesConnectKeyPath",
            "enterprise": true
        }
        """.utf8)

        // WHEN
        let subject: DeleteProvisioningProfileCommand = try JSONDecoder().decode(DeleteProvisioningProfileCommand.self, from: data)

        // THEN
        XCTAssertEqual(subject.provisioningProfileId, "provisioningProfileId")
        XCTAssertEqual(subject.keyIdentifier, "keyIdentifier")
        XCTAssertEqual(subject.issuerID, "issuerID")
        XCTAssertEqual(subject.itunesConnectKeyPath, "/itunesConnectKeyPath")
        XCTAssertTrue(subject.enterprise)
    }

    func test_execute() throws {
        // GIVEN
        var fileDataReads: [Data] = [
            Data("iTunesConnectAPIKey".utf8),
        ]
        files.readPathHandler = { _ in
            fileDataReads.removeFirst()
        }

        // WHEN
        try subject.run()

        // THEN
        assertSnapshot(
            matching: iTunesConnectService.deleteProvisioningProfileArgValues,
            as: .dump
        )
    }
}
