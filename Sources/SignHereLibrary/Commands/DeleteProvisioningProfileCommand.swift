//
//  DeleteProvisioningProfileCommand.swift
//  Commands
//
//  Created by Maxwell Elliott on 04/10/23.
//

import ArgumentParser
import CoreLibrary
import Foundation
import PathKit

internal struct DeleteProvisioningProfileCommand: ParsableCommand {

    internal static var configuration: CommandConfiguration =
        .init(commandName: "delete-provisioning-profile",
              abstract: "Use this command to delete a provisioning profile using its iTunes Connect API ID",
              discussion: """
              This command can be used in conjunction with the `create-provisioning-profile` command to create and delete provisioning profiles.
              """)

    private enum CodingKeys: String, CodingKey {
        case provisioningProfileId = "provisioningProfileId"
        case keyIdentifier = "keyIdentifier"
        case issuerID = "issuerID"
        case itunesConnectKeyPath = "itunesConnectKeyPath"
    }

    @Option(help: "The iTunes Connect API ID of the provisioning profile to delete (https://developer.apple.com/documentation/appstoreconnectapi/profile)")
    internal var provisioningProfileId: String

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
        provisioningProfileId: String,
        keyIdentifier: String,
        issuerID: String,
        itunesConnectKeyPath: String
    ) {
        self.files = files
        self.jsonWebTokenService = jsonWebTokenService
        self.iTunesConnectService = iTunesConnectService
        self.provisioningProfileId = provisioningProfileId
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
            provisioningProfileId: try container.decode(String.self, forKey: .provisioningProfileId),
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
        try iTunesConnectService.deleteProvisioningProfile(
            jsonWebToken: jsonWebToken,
            id: provisioningProfileId
        )
    }
}
