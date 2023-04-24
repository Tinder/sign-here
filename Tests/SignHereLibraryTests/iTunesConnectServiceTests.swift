//
//  iTunesConnectServiceTests.swift
//  SignHereLibraryTests
//
//  Created by Maxwell Elliott on 04/05/23.
//

import CoreLibrary
import CoreLibrary_GeneratedMocks
import CoreLibraryTestKit
import Foundation
@testable import SignHereLibrary
import PathKit
import XCTest

final class iTunesConnectServiceTests: XCTestCase {
    var network: NetworkMock!
    var files: FilesMock!
    var shell: ShellMock!
    var clock: ClockMock!
    var subject: iTunesConnectService!

    override func setUp() {
        super.setUp()
        network = .init()
        files = .init()
        shell = .init()
        clock = .init()
        clock.nowHandler = {
            .init(timeIntervalSince1970: 0)
        }
        subject = iTunesConnectServiceImp(
            network: network,
            files: files,
            shell: shell,
            clock: clock
        )
    }

    override func tearDown() {
        network = nil
        files = nil
        shell = nil
        clock = nil
        subject = nil
        super.tearDown()
    }

    func test_init() {
        XCTAssertNotNil(iTunesConnectServiceImp(
            network: network,
            files: files,
            shell: shell,
            clock: clock
        ))
    }

    func testErrors() {
        assertSnapshot(
            matching: iTunesConnectServiceImp.Error.unableToDetermineITCIdForBundleId(
                bundleIdentifier: "bundleIdentifier"
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: iTunesConnectServiceImp.Error.unableToCreateURL(
                urlComponents: .init()
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: iTunesConnectServiceImp.Error.invalidURL(
                string: "string"
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: iTunesConnectServiceImp.Error.unableToDetermineModulusForCertificate(
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: iTunesConnectServiceImp.Error.unableToDetermineModulusForPrivateKey(
                privateKeyPath: "/privateKeyPath",
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: iTunesConnectServiceImp.Error.unableToBase64DecodeCertificate(
                displayName: "displayName"
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: iTunesConnectServiceImp.Error.unableToDeleteProvisioningProfile(
                id: "id",
                responseData: Data("data".utf8)
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: iTunesConnectServiceImp.Error.unableToDecodeResponse(
                responseData: Data("data".utf8),
                decodingError: .dataCorrupted(.init(codingPath: [], debugDescription: "debugDescription", underlyingError: nil))
            ).description,
            as: .lines
        )
    }

    func test_fetchActiveCertificates_privateKeyMatches() throws {
        // GIVEN
        files.uniqueTemporaryPathHandler = {
            Path("/unique_temporary_path_\(self.files.uniqueTemporaryPathCallCount)")
        }
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 0, data: .init("modulus".utf8), errorData: .init()), // ME: Private Key Modulus
            .init(status: 0, data: .init("modulus".utf8), errorData: .init()) // ME: Certificate Modulus
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }
        var fileDataReads: [Data] = [
            Data("CSRContent".utf8)
        ]
        files.readPathHandler = { _ in
            fileDataReads.removeFirst()
        }
        let jsonEncoder: JSONEncoder = createJSONEncoder()
        var networkExecutes: [Data] = [
            try jsonEncoder.encode(createDownloadCertificateResponse(nextURL: nil))
        ]
        network.executeHandler = { _ in
            networkExecutes.removeFirst()
        }

        // WHEN
        let value: [DownloadCertificateResponse.DownloadCertificateResponseData] = try subject.fetchActiveCertificates(
            jsonWebToken: "jsonWebToken",
            opensslPath: "/opensslPath",
            privateKeyPath: "/privateKeyPath",
            certificateType: "certificateType"
        )

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: value,
            as: .dump
        )
    }

    func test_fetchActiveCertificates_privateKeyMatches_pagedResults() throws {
        // GIVEN
        files.uniqueTemporaryPathHandler = {
            Path("/unique_temporary_path_\(self.files.uniqueTemporaryPathCallCount)")
        }
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 0, data: .init("modulus".utf8), errorData: .init()), // ME: Private Key Modulus
            .init(status: 0, data: .init("modulus".utf8), errorData: .init()), // ME: Certificate Modulus
            .init(status: 0, data: .init("modulus2".utf8), errorData: .init()) // ME: Paged Certificate Modulus
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }
        var fileDataReads: [Data] = [
            Data("CSRContent".utf8)
        ]
        files.readPathHandler = { _ in
            fileDataReads.removeFirst()
        }
        let jsonEncoder: JSONEncoder = createJSONEncoder()
        var networkExecutes: [Data] = [
            try jsonEncoder.encode(createDownloadCertificateResponse(nextURL: try XCTUnwrap(URL(string: "https://api.appstoreconnect.apple.com/nextCertURL")))),
            try jsonEncoder.encode(createDownloadCertificateResponse(nextURL: nil))
        ]
        network.executeHandler = { _ in
            return networkExecutes.removeFirst()
        }

        // WHEN
        let value: [DownloadCertificateResponse.DownloadCertificateResponseData] = try subject.fetchActiveCertificates(
            jsonWebToken: "jsonWebToken",
            opensslPath: "/opensslPath",
            privateKeyPath: "/privateKeyPath",
            certificateType: "certificateType"
        )

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: value,
            as: .dump
        )
    }

    func test_fetchActiveCertificates_privateKeyMatches_failedToDecode() throws {
        // GIVEN
        files.uniqueTemporaryPathHandler = {
            Path("/unique_temporary_path_\(self.files.uniqueTemporaryPathCallCount)")
        }
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 0, data: .init("modulus".utf8), errorData: .init()), // ME: Private Key Modulus
            .init(status: 0, data: .init("modulus".utf8), errorData: .init()), // ME: Certificate Modulus
            .init(status: 0, data: .init("modulus2".utf8), errorData: .init()) // ME: Paged Certificate Modulus
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }
        var fileDataReads: [Data] = [
            Data("CSRContent".utf8)
        ]
        files.readPathHandler = { _ in
            fileDataReads.removeFirst()
        }
        var networkExecutes: [Data] = [
            .init()
        ]
        network.executeHandler = { _ in
            return networkExecutes.removeFirst()
        }

        // WHEN
        XCTAssertThrowsError(try subject.fetchActiveCertificates(
            jsonWebToken: "jsonWebToken",
            opensslPath: "/opensslPath",
            privateKeyPath: "/privateKeyPath",
            certificateType: "certificateType"
        )) {
            if case iTunesConnectServiceImp.Error.unableToDecodeResponse = $0 {
                return
            }
            XCTFail($0.localizedDescription)
        }

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
    }

    func test_fetchActiveCertificates_privateKeyDoesNotMatch() throws {
        // GIVEN
        files.uniqueTemporaryPathHandler = {
            Path("/unique_temporary_path_\(self.files.uniqueTemporaryPathCallCount)")
        }
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 0, data: .init("modulus".utf8), errorData: .init()), // ME: Private Key Modulus
            .init(status: 0, data: .init("othermodulus".utf8), errorData: .init()) // ME: Certificate Modulus
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }
        var fileDataReads: [Data] = [
            Data("CSRContent".utf8)
        ]
        files.readPathHandler = { _ in
            fileDataReads.removeFirst()
        }
        let jsonEncoder: JSONEncoder = createJSONEncoder()
        var networkExecutes: [Data] = [
            try jsonEncoder.encode(createDownloadCertificateResponse(nextURL: nil)),
        ]
        network.executeHandler = { _ in
            return networkExecutes.removeFirst()
        }

        // WHEN
        let value: [DownloadCertificateResponse.DownloadCertificateResponseData] = try subject.fetchActiveCertificates(
            jsonWebToken: "jsonWebToken",
            opensslPath: "/opensslPath",
            privateKeyPath: "/privateKeyPath",
            certificateType: "certificateType"
        )

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
        XCTAssertTrue(value.isEmpty)
    }

    func test_createCertificate() throws {
        // GIVEN
        var fileDataReads: [Data] = [
            Data("CSRContent".utf8)
        ]
        files.readPathHandler = { _ in
            fileDataReads.removeFirst()
        }
        let jsonEncoder: JSONEncoder = createJSONEncoder()
        var networkExecutes: [Data] = [
            try jsonEncoder.encode(createCreateCertificateResponse()),
        ]
        network.executeHandler = { _ in
            return networkExecutes.removeFirst()
        }

        // WHEN
        let value: CreateCertificateResponse = try subject.createCertificate(
            jsonWebToken: "jsonWebToken",
            csr: "/csr",
            certificateType: "certificateType"
        )

        // THEN
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: value,
            as: .dump
        )
    }

    func test_createCertificate_unableToDecodeResponse() throws {
        // GIVEN
        var fileDataReads: [Data] = [
            Data("CSRContent".utf8)
        ]
        files.readPathHandler = { _ in
            fileDataReads.removeFirst()
        }
        var networkExecutes: [Data] = [
            .init()
        ]
        network.executeHandler = { _ in
            return networkExecutes.removeFirst()
        }

        // WHEN
        XCTAssertThrowsError(try subject.createCertificate(
            jsonWebToken: "jsonWebToken",
            csr: "/csr",
            certificateType: "certificateType"
        )) {
            if case iTunesConnectServiceImp.Error.unableToDecodeResponse = $0 {
                return
            }
            XCTFail($0.localizedDescription)
        }

        // THEN
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
    }

    func test_determineBundleIdITCId() throws {
        // GIVEN
        let jsonEncoder: JSONEncoder = createJSONEncoder()
        var networkExecutes: [Data] = [
            try jsonEncoder.encode(createListBundleIDsResponse()),
        ]
        network.executeHandler = { _ in
            return networkExecutes.removeFirst()
        }

        // WHEN
        let value: String = try subject.determineBundleIdITCId(
            jsonWebToken: "jsonWebToken",
            bundleIdentifier: "bundleIdentifier"
        )

        // THEN
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
        XCTAssertEqual(value, "bundleIDITCId")
    }

    func test_determineBundleIdITCId_unableToDecode() throws {
        // GIVEN
        var networkExecutes: [Data] = [
            .init()
        ]
        network.executeHandler = { _ in
            networkExecutes.removeFirst()
        }

        // WHEN
        XCTAssertThrowsError(try subject.determineBundleIdITCId(
            jsonWebToken: "jsonWebToken",
            bundleIdentifier: "bundleIdentifier"
        )) {
            if case iTunesConnectServiceImp.Error.unableToDecodeResponse = $0 {
                return
            }
            XCTFail($0.localizedDescription)
        }

        // THEN
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
    }

    func test_fetchITCDeviceIDs() throws {
        // GIVEN
        let jsonEncoder: JSONEncoder = createJSONEncoder()
        var networkExecutes: [Data] = [
            try jsonEncoder.encode(createListDeviceIDsResponse(nextURL: nil)),
        ]
        network.executeHandler = { _ in
            networkExecutes.removeFirst()
        }

        // WHEN
        let value: Set<String> = try subject.fetchITCDeviceIDs(
            jsonWebToken: "jsonWebToken"
        )

        // THEN
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
        XCTAssertEqual(value.sorted(), ["deviceITCId"])
    }

    func test_fetchITCDeviceIDs_decodeError() throws {
        // GIVEN
        var networkExecutes: [Data] = [
            .init()
        ]
        network.executeHandler = { _ in
            networkExecutes.removeFirst()
        }

        // WHEN
        XCTAssertThrowsError(try subject.fetchITCDeviceIDs(
            jsonWebToken: "jsonWebToken"
        )) {
            if case iTunesConnectServiceImp.Error.unableToDecodeResponse = $0 {
                return
            }
            XCTFail($0.localizedDescription)
        }

        // THEN
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
    }

    func test_fetchITCDeviceIDs_paged() throws {
        // GIVEN
        let jsonEncoder: JSONEncoder = createJSONEncoder()
        var networkExecutes: [Data] = [
            try jsonEncoder.encode(createListDeviceIDsResponse(nextURL: try XCTUnwrap(URL(string: "https://api.appstoreconnect.apple.com/nextCertURL")))),
            try jsonEncoder.encode(createListDeviceIDsResponse(nextURL: nil))
        ]
        network.executeHandler = { _ in
            return networkExecutes.removeFirst()
        }

        // WHEN
        let value: Set<String> = try subject.fetchITCDeviceIDs(
            jsonWebToken: "jsonWebToken"
        )

        // THEN
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
        XCTAssertEqual(value.sorted(), ["deviceITCId"])
    }

    func test_createProfile() throws {
        // GIVEN
        let jsonEncoder: JSONEncoder = createJSONEncoder()
        var networkExecutes: [Data] = [
            try jsonEncoder.encode(createCreateProfileResponse()),
        ]
        network.executeHandler = { _ in
            return networkExecutes.removeFirst()
        }

        // WHEN
        let value: CreateProfileResponse = try subject.createProfile(
            jsonWebToken: "jsonWebToken",
            bundleId: "bundleId",
            certificateId: "certificateId",
            deviceIDs: .init(["deviceId"]),
            profileType: "profileType"
        )

        // THEN
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: value,
            as: .dump
        )
    }

    func test_createProfile_decodingError() throws {
        // GIVEN
        var networkExecutes: [Data] = [
            .init()
        ]
        network.executeHandler = { _ in
            return networkExecutes.removeFirst()
        }

        // WHEN
        XCTAssertThrowsError(try subject.createProfile(
            jsonWebToken: "jsonWebToken",
            bundleId: "bundleId",
            certificateId: "certificateId",
            deviceIDs: .init(["deviceId"]),
            profileType: "profileType"
        )) {
            if case iTunesConnectServiceImp.Error.unableToDecodeResponse = $0 {
                return
            }
            XCTFail($0.localizedDescription)
        }

        // THEN
        assertSnapshot(
            matching: network.executeArgValues,
            as: .dump
        )
    }

    func test_deleteProfile() throws {
        // GIVEN
        network.executeWithStatusCodeHandler = { _ in
            (.init(), [:], 204)
        }

        // WHEN
        try subject.deleteProvisioningProfile(
            jsonWebToken: "jsonWebToken",
            id: "id"
        )

        // THEN
        assertSnapshot(
            matching: network.executeWithStatusCodeArgValues,
            as: .dump
        )
    }

    func test_deleteProfile_failure() {
        // GIVEN
        network.executeWithStatusCodeHandler = { _ in
            (.init(), [:], 400)
        }

        // WHEN
        XCTAssertThrowsError(try subject.deleteProvisioningProfile(
            jsonWebToken: "jsonWebToken",
            id: "id"
        )) {
            if case let iTunesConnectServiceImp.Error.unableToDeleteProvisioningProfile(id: id, responseData: _) = $0 {
                XCTAssertEqual(id, "id")
            } else {
                XCTFail($0.localizedDescription)
            }
        }

        // THEN
        assertSnapshot(
            matching: network.executeWithStatusCodeArgValues,
            as: .dump
        )
    }

    private func createJSONEncoder() -> JSONEncoder {
        let jsonEncoder: JSONEncoder = .init()
        let dateFormatter: DateFormatter = .init()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        jsonEncoder.dateEncodingStrategy = .formatted(dateFormatter)
        return jsonEncoder
    }

    private func createDownloadCertificateResponse(nextURL: URL?) -> DownloadCertificateResponse {
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
                next: nextURL?.absoluteString
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

    private func createListDeviceIDsResponse(nextURL: URL?) -> ListDevicesResponse {
        .init(
            data: [
                ListDevicesResponse.Device(
                    id: "deviceITCId",
                    type: "device",
                    attributes: ListDevicesResponse.Device.Attributes(
                        deviceClass: "deviceClass",
                        model: "model",
                        name: "name",
                        platform: "platform",
                        status: "status",
                        udid: "udid",
                        addedDate: .init()
                    )
                )
            ],
            links: ListDevicesResponse.ListDevicesPagedDocumentLinks(
                next: nextURL?.absoluteString,
                self: "selfLink"
            )
        )
    }

    private func createListBundleIDsResponse() -> ListBundleIDsResponse {
        .init(
            data: [
                ListBundleIDsResponse.BundleId(
                    id: "bundleIDITCId",
                    type: "bundleIds",
                    attributes: ListBundleIDsResponse.BundleId.Attributes(
                        name: "name",
                        identifier: "bundleIdentifier",
                        platform: "IOS"
                    )
                )
            ]
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
                    createdDate: .init(timeIntervalSince1970: 0),
                    profileState: "profileState",
                    profileType: "profileType",
                    expirationDate: .init(timeIntervalSince1970: 100)
                )
            )
        )
    }
}
