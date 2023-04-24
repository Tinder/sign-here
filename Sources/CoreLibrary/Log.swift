//
//  Log.swift
//  CoreLibrary
//
//  Created by Connor Wybranowski on 3/12/21.
//

/// @mockable
public protocol Log {

    func append(_ item: Any, terminator: String)
}

public extension Log {

    func append(_ item: Any) {
        append(item, terminator: "\n")
    }
}

public final class LogImp: Log {

    public init() {}

    public func append(_ item: Any, terminator: String) {
        print(item, terminator: terminator)
    }
}
