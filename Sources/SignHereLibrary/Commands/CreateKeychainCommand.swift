//
//  CreateKeychainCommand.swift
//  Commands
//
//  Created by Maxwell Elliott on 04/24/23.
//

import ArgumentParser
import CoreLibrary
import Foundation

internal struct CreateKeychainCommand: ParsableCommand {

    internal static var configuration: CommandConfiguration =
        .init(commandName: "create-keychain",
              abstract: "Use this command to create a keychain to populate with signing information in the `create-provisioning-profile` command",
              discussion: """
              This command sets up a keychain that is ready to use for signing actions. This command is not required and you may setup your own keychain
              for usage in the `create-provisioning-profile` command.
              """)

    internal enum Error: Swift.Error, CustomStringConvertible {
        case unableToUnlockKeychain(keychainName: String, output: ShellOutput)
        case unableToUpdateKeychainLockTimeout(keychainName: String, output: ShellOutput)
        case unableToCreateKeychain(keychainName: String, output: ShellOutput)

        var description: String {
            switch self {
                case let .unableToUnlockKeychain(keychainName: keychainName, output: output):
                return """
                [CreateKeychainCommand] Unable to unlock keychain
                - Keychain Name: \(keychainName)
                - Output: \(output.outputString)
                - Error: \(output.errorString)
                """
                case let .unableToUpdateKeychainLockTimeout(keychainName: keychainName, output: output):
                return """
                [CreateKeychainCommand] Unable to update keychain lock timeout
                - Keychain Name: \(keychainName)
                - Output: \(output.outputString)
                - Error: \(output.errorString)
                """
                case let .unableToCreateKeychain(keychainName: keychainName, output: output):
                return """
                [CreateKeychainCommand] Unable to create keychain
                - Keychain Name: \(keychainName)
                - Output: \(output.outputString)
                - Error: \(output.errorString)
                """
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case keychainName = "keychainName"
        case keychainPassword = "keychainPassword"
    }

    @Option(help: "Name of the keychain to be created")
    internal var keychainName: String

    @Option(help: "Password for the keychain to be created")
    internal var keychainPassword: String

    private let shell: Shell
    private let keychain: Keychain

    internal init() {
        let shellImp: Shell = ShellImp()
        shell = shellImp
        keychain = KeychainImp(shell: shellImp, processInfo: ProcessInfoImp())
    }

    internal init(
        shell: Shell,
        keychain: Keychain,
        keychainName: String,
        keychainPassword: String
    ) {
        self.shell = shell
        self.keychain = keychain
        self.keychainName = keychainName
        self.keychainPassword = keychainPassword
    }

    internal init(from decoder: Decoder) throws {
        let shellImp: Shell = ShellImp()
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            shell: shellImp,
            keychain: KeychainImp(shell: shellImp, processInfo: ProcessInfoImp()),
            keychainName: try container.decode(String.self, forKey: .keychainName),
            keychainPassword: try container.decode(String.self, forKey: .keychainPassword)
        )
    }

    internal func run() throws {
        try keychain.deleteKeychain(keychainName: keychainName)
        try createKeychain()
        try keychain.setKeychainSearchList(keychainNames: [
            keychainName,
            "login.keychain"
        ])
        try keychain.setDefaultKeychain(keychainName: keychainName)
        try updateKeychainLockTimeout()
        try unlockKeychain()
    }

    private func createKeychain() throws {
        let output: ShellOutput = shell.execute([
            "security",
            "create-keychain",
            "-p",
            keychainPassword,
            keychainName
        ])
        guard output.isSuccessful
        else {
           throw Error.unableToCreateKeychain(
               keychainName: keychainName,
               output: output
           )
        }
    }

    private func updateKeychainLockTimeout() throws {
        let output: ShellOutput = shell.execute([
            "security",
            "set-keychain-settings",
            "-t",
            "7200", // ME: Stay unlocked for 2 hours
            "-l",
            keychainName
        ])
        guard output.isSuccessful
        else {
           throw Error.unableToUpdateKeychainLockTimeout(
               keychainName: keychainName,
               output: output
           )
        }
    }

    private func unlockKeychain() throws {
        let output: ShellOutput = shell.execute([
            "security",
            "unlock-keychain",
            "-p",
            keychainPassword,
            keychainName
        ])
        guard output.isSuccessful
        else {
           throw Error.unableToUnlockKeychain(
               keychainName: keychainName,
               output: output
           )
        }
    }
}
