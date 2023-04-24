//
//  UUID.swift
//  CoreLibrary
//
//  Created by Connor Wybranowski on 5/24/21.
//

import Foundation

/// @mockable(module: prefix = CoreLibrary)
public protocol UUID {

    func make() -> String
}

public final class UUIDImp: UUID {

    public init() {}

    public func make() -> String {
        Foundation.UUID().uuidString
    }
}
