//
//  Platform.swift
//  Models
//
//  Created by Caleb Davis on 06/07/23.
//

import ArgumentParser
import Foundation

enum Platform: String, Decodable, ExpressibleByArgument {
    case iOS = "IOS"
    case macOS = "MAC_OS"
}
