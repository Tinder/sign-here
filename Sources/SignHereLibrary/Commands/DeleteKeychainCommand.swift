//
//  DeleteKeychainCommand.swift
//  Commands
//
//  Created by Maxwell Elliott on 04/06/23.
//

import ArgumentParser
import CoreLibrary
import Foundation

internal struct DeleteKeychainCommand: ParsableCommand {

    internal static var configuration: CommandConfiguration =
        .init(commandName: "delete-keychain",
              abstract: "Use this command to delete a keychain from the system",
              discussion: """
              This command can be used to delete a keychain from the system and restore sensible defaults for the keychain search list post deletion (i.e. setting login.keychain in the default search list)
              """)

    private enum CodingKeys: String, CodingKey {
        case keychainName = "keychainName"
    }

    @Option(help: "Name of the keychain to be deleted")
    internal var keychainName: String

    private let keychain: Keychain

    internal init() {
        keychain = KeychainImp(shell: ShellImp(), processInfo: ProcessInfoImp())
    }

    internal init(
        keychain: Keychain,
        keychainName: String
    ) {
        self.keychain = keychain
        self.keychainName = keychainName
    }

    internal init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            keychain: KeychainImp(shell: ShellImp(), processInfo: ProcessInfoImp()),
            keychainName: try container.decode(String.self, forKey: .keychainName)
        )
    }

    internal func run() throws {
        try keychain.deleteKeychain(keychainName: keychainName)
        try keychain.setKeychainSearchList(keychainNames: ["login.keychain"])
        try keychain.setDefaultKeychain(keychainName: "login.keychain")
    }
}
