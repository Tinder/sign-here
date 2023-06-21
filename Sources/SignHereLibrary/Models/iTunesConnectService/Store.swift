//
//  Store.swift
//  Models
//
//  Created by Caleb Davis on 06/21/23.
//

import Foundation

internal enum Store: String, Codable, CaseIterable, RawRepresentable {
    case iOSAppStore = "IOS_APP_STORE"
    case macAppStore = "MAC_APP_STORE"
    case tvAppStore = "TVOS_APP_STORE"
    case macCatalystAppStore = "MAC_CATALYST_APP_STORE"
}
