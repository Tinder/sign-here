//
//  RegisterDeviceCommand.swift
//  Commands
//
//  Created by Pranavi Gupta on 07/11/23.
//

import ArgumentParser
import CoreLibrary
import Foundation
import PathKit

internal struct RegisterDeviceCommand: ParsableCommand {

    internal static var configuration: CommandConfiguration =
        .init(commandName: "register-device",
              abstract: "Use this command to register a device using its udid",
              discussion: """
              """)

    private enum CodingKeys: String, CodingKey {
        case platform = "platform"
        case name = "name"
        case udid = "udid"
        case keyIdentifier = "keyIdentifier"
        case issuerID = "issuerID"
        case itunesConnectKeyPath = "itunesConnectKeyPath"
    }

    @Option(help: "The operating system intended for the bundle: IOS or MAC_OS (https://developer.apple.com/documentation/appstoreconnectapi/bundleidplatform)")
    internal var platform: String

    @Option(help: "Your Name's Device (example: John's iPhone 13)")
    internal var name: String

    @Option(help: "The device's UDID")
    internal var udid: String

    @Option(help: "The key identifier of the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)")
    internal var keyIdentifier: String

    @Option(help: "The issuer id of the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)")
    internal var issuerID: String

    @Option(help: "The path to the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)")
    internal var itunesConnectKeyPath: String

    private let files: Files
    private let jsonWebTokenService: JSONWebTokenService
    private let iTunesConnectService: iTunesConnectService

    internal init() {
        let filesImp: Files = FilesImp()
        files = filesImp
        jsonWebTokenService = JSONWebTokenServiceImp(clock: ClockImp())
        iTunesConnectService = iTunesConnectServiceImp(
            network: NetworkImp(),
            files: filesImp,
            shell: ShellImp(),
            clock: ClockImp()
        )
    }

    internal init(
        files: Files,
        jsonWebTokenService: JSONWebTokenService,
        iTunesConnectService: iTunesConnectService,
        platform: String,
        name: String,
        udid: String,
        keyIdentifier: String,
        issuerID: String,
        itunesConnectKeyPath: String
    ) {
        self.files = files
        self.jsonWebTokenService = jsonWebTokenService
        self.iTunesConnectService = iTunesConnectService
        self.platform = platform
        self.name = name
        self.udid = udid
        self.keyIdentifier = keyIdentifier
        self.issuerID = issuerID
        self.itunesConnectKeyPath = itunesConnectKeyPath
    }

    internal init(from decoder: Decoder) throws {
        let filesImp: Files = FilesImp()
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            files: filesImp,
            jsonWebTokenService: JSONWebTokenServiceImp(clock: ClockImp()),
            iTunesConnectService: iTunesConnectServiceImp(
                network: NetworkImp(),
                files: filesImp,
                shell: ShellImp(),
                clock: ClockImp()
            ),
            platform: try container.decode(String.self, forKey: .platform),
            name: try container.decode(String.self, forKey: .name),
            udid: try container.decode(String.self, forKey: .udid),
            keyIdentifier: try container.decode(String.self, forKey: .keyIdentifier),
            issuerID: try container.decode(String.self, forKey: .issuerID),
            itunesConnectKeyPath: try container.decode(String.self, forKey: .itunesConnectKeyPath)
        )
    }

    internal func run() throws {
        let jsonWebToken: String = try jsonWebTokenService.createToken(
            keyIdentifier: keyIdentifier,
            issuerID: issuerID,
            secretKey: try files.read(Path(itunesConnectKeyPath))
        )
        try iTunesConnectService.registerDevice(
            jsonWebToken: jsonWebToken,
            platform: platform,
            name: name,
            udid: udid
        )
    }
}
