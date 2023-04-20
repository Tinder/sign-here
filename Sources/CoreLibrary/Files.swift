//
//  Files.swift
//  CoreLibrary
//
//  Created by Connor Wybranowski on 3/9/21.
//

import Foundation
import PathKit

/// @mockable
public protocol Files {

    func read(_ path: Path) throws -> String
    func read(_ path: Path) throws -> Data
    func write(_ string: String, to path: Path) throws
    func write(_ data: Data, to path: Path) throws
    func delete(_ path: Path) throws
    func uniqueTemporaryPath() throws -> Path
}

public final class FilesImp: Files {

    public init() {}

    public func read(_ path: Path) throws -> String {
        try path.read(.utf8)
    }

    public func read(_ path: Path) throws -> Data {
        try path.read()
    }

    public func write(_ string: String, to path: Path) throws {
        try path.write(string)
    }

    public func write(_ data: Data, to path: Path) throws {
        try path.write(data)
    }

    public func delete(_ path: Path) throws {
        try path.delete()
    }

    public func uniqueTemporaryPath() throws -> Path {
        try Path.uniqueTemporary()
    }
}
