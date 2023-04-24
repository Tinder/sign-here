//
//  SignHereCom.swift
//  SignHereLibraryTests
//
//  Created by Maxwell Elliott on 03/28/23.
//

import ArgumentParser
import XCTest

@testable import SignHereLibrary

final class SignHereCom: XCTestCase {

    func testConfiguration() {
        let configuration: CommandConfiguration = SignHereCommand.configuration
        XCTAssertEqual(configuration.commandName, "sign-here")
    }

    func testInit() throws {
        let command: Any = SignHereCommand()
        XCTAssertTrue(command is ParsableCommand)
    }
}
