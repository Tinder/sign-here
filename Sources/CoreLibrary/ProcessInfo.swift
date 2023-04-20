//
//  ProcessInfo.swift
//  CoreLibrary
//
//  Created by Connor Wybranowski on 7/14/21.
//

import Foundation

/// @mockable(module: prefix = CoreLibrary)
public protocol ProcessInfo {

    func environment() -> [String: String]
}

public final class ProcessInfoImp: ProcessInfo {

    private let processInfo: Foundation.ProcessInfo = .processInfo

    public init() {}

    public func environment() -> [String: String] {
        processInfo.environment
    }
}
