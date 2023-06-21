//
//  CreateProvisioningProfileCommandTests.swift
//  SignHereLibraryTests
//
//  Created by Maxwell Elliott on 04/04/23.
//

import ArgumentParser
import CoreLibrary
import CoreLibrary_GeneratedMocks
import CoreLibraryTestKit
import PathKit
import XCTest

@testable import SignHereLibrary
@testable import SignHereLibrary_GeneratedMocks

final class CreateProvisioningProfileCommandTests: XCTestCase {
    var files: FilesMock!
    var log: LogMock!
    var jsonWebTokenService: JSONWebTokenServiceMock!
    var shell: ShellMock!
    var uuid: UUIDMock!
    var iTunesConnectService: iTunesConnectServiceMock!
    var subject: CreateProvisioningProfileCommand!

    override func setUp() {
        super.setUp()
        files = .init()
        log = .init()
        jsonWebTokenService = .init()
        shell = .init()
        uuid = .init()
        uuid.makeHandler = {
            "uuid_\(self.uuid.makeCallCount)"
        }
        iTunesConnectService = .init()
        subject = .init(
            files: files,
            log: log,
            jsonWebTokenService: jsonWebTokenService,
            shell: shell,
            uuid: uuid,
            iTunesConnectService: iTunesConnectService,
            keyIdentifier: "keyIdentifier",
            issuerID: "issuerID",
            privateKeyPath: "privateKeyPath",
            itunesConnectKeyPath: "itunesConnectKeyPath",
            keychainName: "keychainName",
            keychainPassword: "keychainPassword",
            bundleIdentifier: "bundleIdentifier",
            profileType: "profileType",
            certificateType: "certificateType",
            outputPath: "/outputPath",
            opensslPath: "/opensslPath",
            intermediaryAppleCertificates: ["/intermediaryAppleCertificate"],
            certificateSigningRequestSubject: "certificateSigningRequestSubject",
            bundleIdentifierName: "bundleIdentifierName",
            platform: .iOS
        )
    }

    override func tearDown() {
        files = nil
        log = nil
        jsonWebTokenService = nil
        shell = nil
        uuid = nil
        iTunesConnectService = nil
        subject = nil
        super.tearDown()
    }

    func testConfiguration() {
        let configuration: CommandConfiguration = CreateProvisioningProfileCommand.configuration
        XCTAssertEqual(configuration.commandName, "create-provisioning-profile")
    }

    func testInit() throws {
        let command: Any = CreateProvisioningProfileCommand()
        XCTAssertTrue(command is ParsableCommand)
    }

    func testErrors() {
        assertSnapshot(
            matching: CreateProvisioningProfileCommand.Error.unableToCreatePrivateKeyAndCSR(
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: CreateProvisioningProfileCommand.Error.unableToCreateP12Identity(
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: CreateProvisioningProfileCommand.Error.unableToBase64DecodeCertificate(
                displayName: "displayName"
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: CreateProvisioningProfileCommand.Error.unableToCreatePEM(
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: CreateProvisioningProfileCommand.Error.unableToBase64DecodeProfile(
                name: "name"
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: CreateProvisioningProfileCommand.Error.unableToUpdateKeychainPartitionList(
                keychainName: "keychainName",
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: CreateProvisioningProfileCommand.Error.unableToImportP12IdentityIntoKeychain(
                keychainName: "keychainName",
                p12Identity: "/p12Identity",
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: CreateProvisioningProfileCommand.Error.unableToCreateCSR(
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: CreateProvisioningProfileCommand.Error.unableToImportIntermediaryAppleCertificate(
               certificate: "/certificate",
               output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
    }

    func test_initDecoder() throws {
        // GIVEN
        let data: Data = .init("""
        {
            "keyIdentifier": "keyIdentifier",
            "issuerID": "issuerID",
            "privateKeyPath": "privateKeyPath",
            "itunesConnectKeyPath": "itunesConnectKeyPath",
            "keychainName": "keychainName",
            "keychainPassword": "keychainPassword",
            "bundleIdentifier": "bundleIdentifier",
            "profileType": "profileType",
            "certificateType": "certificateType",
            "outputPath": "/outputPath",
            "opensslPath": "/opensslPath",
            "certificateSigningRequestSubject": "certificateSigningRequestSubject",
            "bundleIdentifierName": "bundleIdentifierName",
            "platform": "IOS"
        }
        """.utf8)

        // WHEN
        let subject: CreateProvisioningProfileCommand = try JSONDecoder().decode(CreateProvisioningProfileCommand.self, from: data)

        // THEN
        XCTAssertEqual(subject.keyIdentifier, "keyIdentifier")
        XCTAssertEqual(subject.issuerID, "issuerID")
        XCTAssertEqual(subject.privateKeyPath, "privateKeyPath")
        XCTAssertEqual(subject.itunesConnectKeyPath, "itunesConnectKeyPath")
        XCTAssertEqual(subject.keychainName, "keychainName")
        XCTAssertEqual(subject.keychainPassword, "keychainPassword")
        XCTAssertEqual(subject.bundleIdentifier, "bundleIdentifier")
        XCTAssertEqual(subject.profileType, "profileType")
        XCTAssertEqual(subject.certificateType, "certificateType")
        XCTAssertEqual(subject.outputPath, "/outputPath")
        XCTAssertEqual(subject.bundleIdentifierName, "bundleIdentifierName")
        XCTAssertEqual(subject.platform, .iOS)
    }

    func test_execute_alreadyActiveCertificate() throws {
        // GIVEN
        files.uniqueTemporaryPathHandler = {
            Path("/unique_temporary_path_\(self.files.uniqueTemporaryPathCallCount)")
        }
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 0, data: .init("createCSR".utf8), errorData: .init()),
            .init(status: 0, data: .init("createPEM".utf8), errorData: .init()),
            .init(status: 0, data: .init("createP12Identity".utf8), errorData: .init()),
            .init(status: 0, data: .init("importP12IdentityIntoKeychain".utf8), errorData: .init()),
            .init(status: 0, data: .init("importIntermediateAppleCertificate".utf8), errorData: .init()),
            .init(status: 0, data: .init("updateKeychainPartitionList".utf8), errorData: .init())
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }
        var fileDataReads: [Data] = [
            Data("iTunesConnectAPIKey".utf8)
        ]
        files.readPathHandler = { _ in
            fileDataReads.removeFirst()
        }
        iTunesConnectService.fetchActiveCertificatesHandler = { _, _, _, _ in
            self.createDownloadCertificateResponse().data
        }
        iTunesConnectService.createCertificateHandler = { _, _, _ in
            self.createCreateCertificateResponse()
        }
        iTunesConnectService.createProfileHandler = { _, _, _, _, _ in
            self.createCreateProfileResponse()
        }

        // WHEN
        try subject.run()

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: log.appendArgValues,
            as: .dump
        )
    }

    func test_execute_noActiveCertificates() throws {
        // GIVEN
        files.uniqueTemporaryPathHandler = {
            Path("/unique_temporary_path_\(self.files.uniqueTemporaryPathCallCount)")
        }
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 0, data: .init("createCSR".utf8), errorData: .init()),
            .init(status: 0, data: .init("createPEM".utf8), errorData: .init()),
            .init(status: 0, data: .init("createP12Identity".utf8), errorData: .init()),
            .init(status: 0, data: .init("importP12IdentityIntoKeychain".utf8), errorData: .init()),
            .init(status: 0, data: .init("importIntermediateAppleCertificate".utf8), errorData: .init()),
            .init(status: 0, data: .init("updateKeychainPartitionList".utf8), errorData: .init())
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }
        var fileDataReads: [Data] = [
            Data("iTunesConnectAPIKey".utf8),
        ]
        files.readPathHandler = { _ in
            fileDataReads.removeFirst()
        }
        iTunesConnectService.createCertificateHandler = { _, _, _ in
            self.createCreateCertificateResponse()
        }
        iTunesConnectService.createProfileHandler = { _, _, _, _, _ in
            self.createCreateProfileResponse()
        }

        // WHEN
        try subject.run()

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: log.appendArgValues,
            as: .dump
        )
    }

    private func createDownloadCertificateResponse() -> DownloadCertificateResponse {
        DownloadCertificateResponse(
            data: [
                DownloadCertificateResponse.DownloadCertificateResponseData(
                    id: "activeCertID",
                    attributes: DownloadCertificateResponse.DownloadCertificateResponseData.DownloadCertificateResponseDataAttributes(
                        certificateContent: "dGVzdAo=",
                        certificateType: "certificateType",
                        expirationDate: .init(timeIntervalSince1970: 100),
                        displayName: "activeCertDisplayName"
                    )
                )
            ],
            links: DownloadCertificateResponse.PagedDocumentLinks(
                self: "self",
                next: "https://api.appstoreconnect.apple.com/nextCertLink"
            )
        )
    }

    private func createEmptyDownloadCertificateResponse() -> DownloadCertificateResponse {
        DownloadCertificateResponse(
            data: [],
            links: DownloadCertificateResponse.PagedDocumentLinks(
                self: "self"
            )
        )
    }

    private func createCreateCertificateResponse() -> CreateCertificateResponse {
        CreateCertificateResponse(
            data: CreateCertificateResponse.CreateCertificateData(
                id: "createdCertID",
                type: "certificates",
                attributes: CreateCertificateResponse.CreateCertificateData.CreateCertificateResponseAttributes(
                    certificateContent: "dGVzdAo=",
                    displayName: "createdCertDisplayName",
                    name: "createdCertName",
                    certificateType: "certificateType",
                    serialNumber: "createdCertSerialNumber"
                )
            )
        )
    }

    private func createCreateProfileResponse() -> CreateProfileResponse {
        .init(
            data: CreateProfileResponse.CreateProfileResponseData(
                id: "createdProfileITCID",
                type: "type",
                attributes: CreateProfileResponse.CreateProfileResponseData.Attributes(
                    profileContent: "dGVzdAo=",
                    uuid: "uuid",
                    name: "createdProfileName",
                    platform: "platform",
                    createdDate: .init(),
                    profileState: "profileState",
                    profileType: "profileType",
                    expirationDate: .init(timeIntervalSince1970: 100)
                )
            )
        )
    }
}
