//
//  Clock.swift
//  CoreLibrary
//
//  Created by Connor Wybranowski on 3/26/21.
//

import Foundation

/// @mockable
public protocol Clock {

    func now() -> Date
}

public struct ClockImp: Clock {

    public init() {}

    public func now() -> Date {
        Date()
    }
}
