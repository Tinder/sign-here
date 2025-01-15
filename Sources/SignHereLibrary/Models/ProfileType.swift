//
//  ProfileType.swift
//  Models
//
//  Created by Omar Zuniga on 29/05/24.
//

import Foundation

enum ProfileType {
    case development
    case adHoc
    case appStore
    case inHouse
    case direct
    case unknown

    init(rawValue: String) {
        switch rawValue {
        case let str where str.hasSuffix("_APP_DEVELOPMENT"): self = .development
        case let str where str.hasSuffix("_APP_ADHOC"): self = .adHoc
        case let str where str.hasSuffix("_APP_STORE"): self = .appStore
        case let str where str.hasSuffix("_APP_INHOUSE"): self = .inHouse
        case let str where str.hasSuffix("_APP_DIRECT"): self = .direct
        default: self = .unknown
        }
    }

    var usesDevices: Bool {
        switch self {
            case .appStore, .inHouse: return false
            default: return true
        }
    }
}
