//
//  SignHereCommand.swift
//  SignHereLibrary
//
//  Created by Maxwell Elliott on 04/19/23.
//

import ArgumentParser

public struct SignHereCommand: ParsableCommand {

    public static var configuration: CommandConfiguration =
        .init(commandName: "sign-here",
              subcommands: [
            ])

    public init() {
        // NoOp
    }
}
