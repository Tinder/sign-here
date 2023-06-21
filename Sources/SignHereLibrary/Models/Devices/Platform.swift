//
//  Platform.swift
//  Models
//
//  Created by Caleb Davis on 06/07/23.
//

import ArgumentParser
import Foundation

internal enum Platform: String, Codable, ExpressibleByArgument {
    case iOS = "IOS"
    case macOS = "MAC_OS"
}

