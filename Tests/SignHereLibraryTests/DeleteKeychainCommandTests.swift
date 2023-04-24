//
//  DeleteKeychainCommandTests.swift
//  SignHereLibraryTests
//
//  Created by Maxwell Elliott on 04/06/23.
//

import ArgumentParser
import CoreLibrary
import CoreLibrary_GeneratedMocks
import CoreLibraryTestKit
import XCTest

@testable import SignHereLibrary
@testable import SignHereLibrary_GeneratedMocks

final class DeleteKeychainCommandTests: XCTestCase {
    var keychain: KeychainMock!
    var subject: DeleteKeychainCommand!

    override func setUp() {
        super.setUp()
        keychain = .init()
        subject = .init(
            keychain: keychain,
            keychainName: "keychainName"
        )
    }

    override func tearDown() {
        keychain = nil
        subject = nil
        super.tearDown()
    }

    func testConfiguration() {
        let configuration: CommandConfiguration = DeleteKeychainCommand.configuration
        XCTAssertEqual(configuration.commandName, "delete-keychain")
    }

    func testInit() throws {
        let command: Any = DeleteKeychainCommand()
        XCTAssertTrue(command is ParsableCommand)
    }


    func test_initDecoder() throws {
        // GIVEN
        let data: Data = .init("""
        {
            "keychainName": "keychainName"
        }
        """.utf8)

        // WHEN
        let subject: DeleteKeychainCommand = try JSONDecoder().decode(DeleteKeychainCommand.self, from: data)

        // THEN
        XCTAssertEqual(subject.keychainName, "keychainName")
    }

    func test_execute() throws {
        // WHEN
        try subject.run()

        // THEN
        assertSnapshot(
            matching: keychain.deleteKeychainArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: keychain.setKeychainSearchListArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: keychain.setDefaultKeychainArgValues,
            as: .dump
        )
    }

    func test_execute_deleteKeychain_failed() throws {
        // GIVEN
        struct TestError: Swift.Error {}
        keychain.deleteKeychainHandler = { _ in
            throw TestError()
        }

        // WHEN
        XCTAssertThrowsError(try subject.run())

        // THEN
        assertSnapshot(
            matching: keychain.deleteKeychainArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: keychain.setKeychainSearchListArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: keychain.setDefaultKeychainArgValues,
            as: .dump
        )
    }

    func test_execute_setKeychainSearchList_failed() throws {
        // GIVEN
        struct TestError: Swift.Error {}
        keychain.setKeychainSearchListHandler = { _ in
            throw TestError()
        }

        // WHEN
        XCTAssertThrowsError(try subject.run())

        // THEN
        assertSnapshot(
            matching: keychain.deleteKeychainArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: keychain.setKeychainSearchListArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: keychain.setDefaultKeychainArgValues,
            as: .dump
        )
    }

    func test_execute_setDefaultKeychain_failed() throws {
        // GIVEN
        struct TestError: Swift.Error {}
        keychain.setDefaultKeychainHandler = { _ in
            throw TestError()
        }

        // WHEN
        XCTAssertThrowsError(try subject.run())

        // THEN
        assertSnapshot(
            matching: keychain.deleteKeychainArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: keychain.setKeychainSearchListArgValues,
            as: .dump
        )
        assertSnapshot(
            matching: keychain.setDefaultKeychainArgValues,
            as: .dump
        )
    }
}
