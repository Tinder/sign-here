//
//  CreateKeychainCommandTests.swift
//  SignHereLibraryTests
//
//  Created by Maxwell Elliott on 04/04/23.
//

import ArgumentParser
import CoreLibrary
import CoreLibrary_GeneratedMocks
import CoreLibraryTestKit
import XCTest

@testable import SignHereLibrary

final class CreateKeychainCommandTests: XCTestCase {
    var shell: ShellMock!
    var keychain: KeychainMock!
    var log: LogMock!
    var subject: CreateKeychainCommand!

    override func setUp() {
        super.setUp()
        shell = .init()
        keychain = .init()
        log = .init()
        subject = .init(
            shell: shell,
            keychain: keychain,
            log: log,
            keychainName: "keychainName",
            keychainPassword: "keychainPassword"
        )
    }

    override func tearDown() {
        shell = nil
        keychain = nil
        log = nil
        subject = nil
        super.tearDown()
    }

    func testConfiguration() {
        let configuration: CommandConfiguration = CreateKeychainCommand.configuration
        XCTAssertEqual(configuration.commandName, "create-keychain")
    }

    func test_init() throws {
        let command: Any = CreateKeychainCommand()
        XCTAssertTrue(command is ParsableCommand)
    }

    func testErrors() {
        assertSnapshot(
            matching: CreateKeychainCommand.Error.unableToUnlockKeychain(
                keychainName: "keychainName",
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: CreateKeychainCommand.Error.unableToUpdateKeychainLockTimeout(
                keychainName: "keychainName",
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        assertSnapshot(
            matching: CreateKeychainCommand.Error.unableToCreateKeychain(
                keychainName: "keychainName",
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
        
        assertSnapshot(
            matching: CreateKeychainCommand.Error.unableToListKeychains(
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )

        assertSnapshot(
            matching: CreateKeychainCommand.Error.unableToFindKeychain(
                keychainName: "keychainName",
                output: .init(status: 0, data: .init("output".utf8), errorData: .init("errorOutput".utf8))
            ).description,
            as: .lines
        )
    }

    func test_initDecoder() throws {
        // GIVEN
        let data: Data = .init("""
        {
            "keychainName": "keychainName",
            "keychainPassword": "keychainPassword"
        }
        """.utf8)
        // WHEN
        let subject: CreateKeychainCommand = try JSONDecoder().decode(CreateKeychainCommand.self, from: data)

        // THEN
        XCTAssertEqual(subject.keychainName, "keychainName")
        XCTAssertEqual(subject.keychainPassword, "keychainPassword")
    }

    func test_execute_cannotCreateKeychain() throws {
        // GIVEN
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 1, data: .init("createKeychain".utf8), errorData: .init()),
            .init(status: 0, data: .init("updateKeychainLockTimeout".utf8), errorData: .init()),
            .init(status: 0, data: .init("unlockKeychain".utf8), errorData: .init()),
            .init(status: 0, data: .init("listKeychain".utf8), errorData: .init())
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }

        // WHEN
        XCTAssertThrowsError(try subject.run()) {
            if case CreateKeychainCommand.Error.unableToCreateKeychain(keychainName: _, output: _) = $0 {
                XCTAssertTrue(true)
            } else {
                XCTFail($0.localizedDescription)
            }
        }

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
    }

    func test_execute_cannotUpdateKeychainLockTimeout() throws {
        // GIVEN
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 0, data: .init("createKeychain".utf8), errorData: .init()),
            .init(status: 1, data: .init("updateKeychainLockTimeout".utf8), errorData: .init()),
            .init(status: 0, data: .init("unlockKeychain".utf8), errorData: .init()),
            .init(status: 0, data: .init("listKeychain".utf8), errorData: .init())
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }

        // WHEN
        XCTAssertThrowsError(try subject.run()) {
            if case CreateKeychainCommand.Error.unableToUpdateKeychainLockTimeout(keychainName: _, output: _) = $0 {
                XCTAssertTrue(true)
            } else {
                XCTFail($0.localizedDescription)
            }
        }

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
    }

    func test_execute_cannotUnlockKeychain() throws {
        // GIVEN
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 0, data: .init("createKeychain".utf8), errorData: .init()),
            .init(status: 0, data: .init("updateKeychainLockTimeout".utf8), errorData: .init()),
            .init(status: 1, data: .init("unlockKeychain".utf8), errorData: .init()),
            .init(status: 0, data: .init("listKeychain".utf8), errorData: .init()),
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }

        // WHEN
        XCTAssertThrowsError(try subject.run()) {
            if case CreateKeychainCommand.Error.unableToUnlockKeychain(keychainName: _, output: _) = $0 {
                XCTAssertTrue(true)
            } else {
                XCTFail($0.localizedDescription)
            }
        }

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
    }

    func test_execute_cannotListKeychain() throws {
        // GIVEN
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 0, data: .init("createKeychain".utf8), errorData: .init()),
            .init(status: 0, data: .init("updateKeychainLockTimeout".utf8), errorData: .init()),
            .init(status: 0, data: .init("unlockKeychain".utf8), errorData: .init()),
            .init(status: 1, data: .init("listKeychain".utf8), errorData: .init()),
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }

        // WHEN
        XCTAssertThrowsError(try subject.run()) {
            if case CreateKeychainCommand.Error.unableToListKeychains(output: _) = $0 {
                XCTAssertTrue(true)
            } else {
                XCTFail($0.localizedDescription)
            }
        }

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
    }

    func test_execute_cannotFindKeychain() throws {
        // GIVEN
        var executeLaunchPaths: [ShellOutput] = [
            .init(status: 0, data: .init("createKeychain".utf8), errorData: .init()),
            .init(status: 0, data: .init("updateKeychainLockTimeout".utf8), errorData: .init()),
            .init(status: 0, data: .init("unlockKeychain".utf8), errorData: .init()),
            .init(status: 0, data: .init("listKeychain".utf8), errorData: .init()),
        ]
        shell.executeLaunchPathHandler = { _, _, _, _ in
            executeLaunchPaths.removeFirst()
        }

        // WHEN
        XCTAssertThrowsError(try subject.run()) {
            if case CreateKeychainCommand.Error.unableToFindKeychain(keychainName: _, output: _) = $0 {
                XCTAssertTrue(true)
            } else {
                XCTFail($0.localizedDescription)
            }
        }

        // THEN
        assertSnapshot(
            matching: shell.executeLaunchPathArgValues,
            as: .dump
        )
    }
}
