//
//  SignHereCommand.swift
//  Commands
//
//  Created by Maxwell Elliott on 04/24/23.
//

import ArgumentParser

public struct SignHereCommand: ParsableCommand {

    public static var configuration: CommandConfiguration =
        .init(
            commandName: "sign-here",
            abstract: "A straightforward tool to allow for the creation of Provisioning Profiles and Certificates for deploying Apple based software",
            subcommands: [
                CreateKeychainCommand.self,
                DeleteKeychainCommand.self,
                DeleteProvisioningProfileCommand.self,
                CreateProvisioningProfileCommand.self,
                RegisterDeviceCommand.self
            ]
        )

    public init() {
        // NoOp
    }
}
