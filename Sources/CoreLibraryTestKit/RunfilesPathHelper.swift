//
//  RunfilesPathHelper.swift
//  CoreLibraryTestKit
//
//  Created by Maxwell Elliott on 3/12/22
//

import Foundation
import PathKit

internal class RunfilesPathHelper {

    internal enum Error: Swift.Error, CustomStringConvertible {
        case cannotFindEnvironmentVariable(String)

        internal var description: String {
            switch self {
            case let .cannotFindEnvironmentVariable(variable):
                return "[RunfilesPathHelper] Cannot find \(variable) in environment"
            }
        }
    }

    class func determineRunfilesPath(processInfo: ProcessInfo) throws -> Path {
        guard let testSrcDir: String = ProcessInfo.processInfo.environment["TEST_SRCDIR"]
        else {
            throw Error.cannotFindEnvironmentVariable("TEST_SRCDIR")
        }
        guard let testWorkspaceName: String = ProcessInfo.processInfo.environment["TEST_WORKSPACE"]
        else {
            throw Error.cannotFindEnvironmentVariable("TEST_WORKSPACE")
        }
        guard let testBinary: String = ProcessInfo.processInfo.environment["TEST_BINARY"]
        else {
            throw Error.cannotFindEnvironmentVariable("TEST_BINARY")
        }
        return (Path(testSrcDir)
            + testWorkspaceName
            + testBinary.replacingOccurrences(of: "UnitTests", with: "LibraryTests").replacingOccurrences(of: ".test-runner.sh", with: "")).parent()
    }
}
