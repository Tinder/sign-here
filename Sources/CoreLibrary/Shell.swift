//
//  Shell.swift
//  CoreLibrary
//
//  Created by Connor Wybranowski on 3/9/21.
//

import Foundation
import PathKit

public struct ShellOutput: Equatable {

    public let status: Int
    public let outputData: Data
    public let errorData: Data

    public var outputString: String {
        String(decoding: outputData, as: UTF8.self)
    }

    public var errorString: String {
        String(decoding: errorData, as: UTF8.self)
    }

    public var isSuccessful: Bool {
        status == 0
    }

    public init(
        status: Int,
        data: Data,
        errorData: Data
    ) {
        self.status = status
        self.outputData = data
        self.errorData = errorData
    }
}

/// @mockable
public protocol Shell {

    func execute(
        launchPath: String,
        _ arguments: [String],
        environment: [String: String]?) -> ShellOutput
    func execute(
        launchPath: String,
        _ arguments: [String],
        environment: [String: String]?,
        stdinData: Data?) -> ShellOutput
    func execute(
        launchPath: String,
        _ arguments: [String],
        path: Path,
        environment: [String: String]?) -> ShellOutput
}

public extension Shell {

    @discardableResult
    func execute(
        launchPath: String = "/usr/bin/env",
        _ arguments: [String],
        environment: [String: String]? = nil
    ) -> ShellOutput {
        execute(launchPath: launchPath, arguments, environment: environment, stdinData: nil)
    }

    @discardableResult
    func execute(
        launchPath: String = "/usr/bin/env",
        _ arguments: String...,
        environment: [String: String]? = nil
    ) -> ShellOutput {
        execute(launchPath: launchPath, arguments, environment: environment, stdinData: nil)
    }

    @discardableResult
    func execute(
        launchPath: String = "/usr/bin/env",
        _ arguments: String...,
        path: Path,
        environment: [String: String]? = nil
    ) -> ShellOutput {
        execute(launchPath: launchPath, arguments, path: path, environment: environment)
    }

    @discardableResult
    func execute(
        launchPath: String = "/usr/bin/env",
        _ arguments: [String],
        path: Path,
        environment: [String: String]? = nil
    ) -> ShellOutput {
        execute(launchPath: launchPath, arguments, path: path, environment: environment)
    }
}

public final class ShellImp: Shell {

    public init() {}

    @discardableResult
    public func execute(
        launchPath: String,
        _ arguments: [String],
        environment: [String: String]?,
        stdinData: Data?
    ) -> ShellOutput {
        var tempData: Data = .init()
        var tempErrorData: Data = .init()
        var tempTerminationStatus: Int = 1
        // [CW] 11/24/21 - Manual autoreleasepool is required to explicitly reduce
        // peak memory usage, as described here: https://stackoverflow.com/a/25880106/14635725
        // This is not a problem for most consumers, however resource-intensive consumers
        // (aka consumers that trigger many 'execute' invocations in a tight loop that each
        // manage a potentially large output on STDOUT and/or STDERR) will hit a memory
        // ceiling and ultimately crash. Explicit autoreleasepool ensures this doesn't happen.
        autoreleasepool {
            let (data, errorData, terminationStatus): (Data, Data, Int32) = makeAndLaunchProcess(
                launchPath: launchPath,
                arguments,
                environment: environment,
                stdinData: stdinData)
            tempData = data
            tempErrorData = errorData
            tempTerminationStatus = Int(terminationStatus)
        }
        return ShellOutput(
            status: tempTerminationStatus,
            data: tempData,
            errorData: tempErrorData)
    }

    @discardableResult
    public func execute(
        launchPath: String,
        _ arguments: [String],
        path: Path,
        environment: [String: String]?
    ) -> ShellOutput {
        var output: ShellOutput = .init(status: 1, data: Data("".utf8), errorData: Data("".utf8))
        path.chdir { output = execute(launchPath: launchPath, arguments, environment: environment) }
        return output
    }

    private func makeAndLaunchProcess(
        launchPath: String,
        _ arguments: [String],
        environment: [String: String]?,
        stdinData: Data?
    ) -> (data: Data, errorData: Data, terminationStatus: Int32) {
        let process: Process = .init()
        process.launchPath = launchPath
        process.arguments = arguments

        // [CW] 5/18/21 - Explicitly setting 'process.environment' results
        // in overwriting the available environment, even if the value is nil.
        if let environment = environment {
            process.environment = environment
        }

        let outputPipe: Pipe = .init()
        let errorPipe: Pipe = .init()
        let stdinPipe: Pipe = .init()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.standardInput = stdinPipe

        // [CW] 3/9/21 - Must read data as the output is being generated to
        // avoid exceeding the size of the buffer, and causing the execution
        // to hang. While this may not be a problem for commands that generate
        // little or no output, other commands will not work as expected without
        // it. See the following for more info:
        // https://forums.swift.org/t/the-problem-with-a-frozen-process-in-swift-process-class/39579/6
        let readabilityHandler: (FileHandle, Pipe, inout Data) -> Void = { fileHandle, pipe, data in
            let availableData: Data = fileHandle.availableData
            if availableData.isEmpty {
                pipe.fileHandleForReading.readabilityHandler = nil
            } else {
                data.append(availableData)
            }
        }

        var data: Data = .init()
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            readabilityHandler(fileHandle, outputPipe, &data)
        }

        var errorData: Data = .init()
        errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            readabilityHandler(fileHandle, errorPipe, &errorData)
        }

        process.launch()

        if let stdinData = stdinData {
            stdinPipe.fileHandleForWriting.write(stdinData)
            try? stdinPipe.fileHandleForWriting.close()
        }

        process.waitUntilExit()
        return (
            data: data,
            errorData: errorData,
            terminationStatus: process.terminationStatus)
    }
}
