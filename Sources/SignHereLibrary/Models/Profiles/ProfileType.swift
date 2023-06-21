//
//  ProfileType.swift
//  Models
//
//  Created by Caleb Davis on 06/21/23.
//

import ArgumentParser
import Foundation

internal enum ProfileType: String, Codable, ExpressibleByArgument {
    case iOSAppDevelopment = "IOS_APP_DEVELOPMENT"
    case iOSAppStore = "IOS_APP_STORE"
    case iOSAppAdhoc = "IOS_APP_ADHOC"
    case iOSAppInhouse = "IOS_APP_INHOUSE"
    case macAppDevelopment = "MAC_APP_DEVELOPMENT"
    case macAppStore = "MAC_APP_STORE"
    case macAppDirect = "MAC_APP_DIRECT"
    case tvOSAppDevelopment = "TVOS_APP_DEVELOPMENT"
    case tvOSAppStore = "TVOS_APP_STORE"
    case tvOSAppAdhoc = "TVOS_APP_ADHOC"
    case tvOSAppInhouse = "TVOS_APP_INHOUSE"
    case macCatalystAppDevelopment = "MAC_CATALYST_APP_DEVELOPMENT"
    case macCatalystAppStore = "MAC_CATALYST_APP_STORE"
    case macCatalystAppDirect = "MAC_CATALYST_APP_DIRECT"
}
