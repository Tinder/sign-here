//
//  Keychain.swift
//  CoreLibrary
//
//  Created by Maxwell Elliott on 11/3/22.
//

/// @mockable
public protocol Keychain {
    func setDefaultKeychain(keychainName: String) throws
    func setKeychainSearchList(keychainNames: [String]) throws
    func deleteKeychain(keychainName: String) throws
}

public final class KeychainImp: Keychain {

    internal enum Constants {
        static let securityToolPath: String = "/usr/bin/security"
    }

    private let shell: Shell
    private let processInfo: CoreLibrary.ProcessInfo

    public enum Error: Swift.Error, CustomStringConvertible {
        case unableToSetDefaultKeychain(keychainName: String, output: ShellOutput)
        case unableToUpdateKeychainSearchList(output: ShellOutput)
        case unableToDeleteKeychain(keychainName: String, output: ShellOutput)

        public var description: String {
            switch self {
            case let .unableToSetDefaultKeychain(keychainName: keychainName, output: output):
                return """
                [KeychainImp] Unable to set default keychain
                - Keychain Name: \(keychainName)
                - Output: \(output.outputString)
                - Error: \(output.errorString)
                """
            case let .unableToUpdateKeychainSearchList(output: output):
                return """
                [KeychainImp] Unable to update keychain search list
                - Output: \(output.outputString)
                - Error: \(output.errorString)
                """
            case let .unableToDeleteKeychain(keychainName: keychainName, output: output):
                return """
                [KeychainImp] Unable to delete existing keychain
                - Keychain Name: \(keychainName)
                - Output: \(output.outputString)
                - Error: \(output.errorString)
                """
            }
        }
    }

    public init(shell: Shell, processInfo: CoreLibrary.ProcessInfo) {
        self.shell = shell
        self.processInfo = processInfo
    }

    public func setDefaultKeychain(keychainName: String) throws {
        let output: ShellOutput = shell.execute([
            Constants.securityToolPath,
            "default-keychain",
            "-s",
            keychainName
        ])
        guard output.isSuccessful
        else {
           throw Error.unableToSetDefaultKeychain(
               keychainName: keychainName,
               output: output
           )
        }
    }

    public func setKeychainSearchList(keychainNames: [String]) throws {
        let output: ShellOutput = shell.execute([
            Constants.securityToolPath,
            "list-keychains",
            "-d",
            "user",
            "-s"
        ] + keychainNames)
        guard output.isSuccessful
        else {
           throw Error.unableToUpdateKeychainSearchList(
               output: output
           )
        }
    }

    public func deleteKeychain(keychainName: String) throws {
        let output: ShellOutput = shell.execute([
            Constants.securityToolPath,
            "delete-keychain",
            keychainName
        ])
        guard output.isSuccessful
        else {
            if output.errorString.contains("security: SecKeychainDelete: The specified keychain could not be found.") {
                return
            }
            throw Error.unableToDeleteKeychain(
                keychainName: keychainName,
                output: output
            )
        }
    }
}
