//
//  AssertSnapshot.swift
//  CoreLibraryTestKit
//
//  Created by Connor Wybranowski on 3/18/21.
//

import Foundation
import PathKit
import SnapshotTesting
import XCTest

public var isRecording: Bool {
    get {
        SnapshotTesting.isRecording
    }
    set {
        SnapshotTesting.isRecording = newValue
    }
}

public func assertSnapshot<Value, Format>(
    matching value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, Format>,
    named name: String? = nil,
    record recording: Bool = (ProcessInfo.processInfo.environment["RERECORD_SNAPSHOTS"] ?? "FALSE") == "TRUE",
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    let snapshotDirectory: String
    if let passedSnapshotDirectory: String = ProcessInfo.processInfo.environment["SNAPSHOT_DIRECTORY"] {
        // [CW] 3/14/23 - Allows command-line invocations to record snapshots.
        if let buildWorkspaceDirectory: String = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
            let snapshotDirectoryPath: Path = Path(buildWorkspaceDirectory)
                + Path(passedSnapshotDirectory.replacingOccurrences(of: "$BUILD_WORKSPACE_DIRECTORY/", with: ""))
            snapshotDirectory = snapshotDirectoryPath.string
        } else {
            snapshotDirectory = passedSnapshotDirectory
        }
    } else {
        do {
            snapshotDirectory = try RunfilesPathHelper.determineRunfilesPath(
                processInfo: ProcessInfo.processInfo
            ).string
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    let fileURL = URL(fileURLWithPath: "\(file)", isDirectory: false)
    let fileName = fileURL.deletingPathExtension().lastPathComponent

    let snapshotDirectoryPath: Path = .init(snapshotDirectory)
      + "__Snapshots__"
      + Path(fileName)

    let failure = verifySnapshot(
      matching: try value(),
      as: snapshotting,
      named: name,
      record: recording,
      snapshotDirectory: snapshotDirectoryPath.absolute().string,
      timeout: timeout,
      file: file,
      testName: "\(fileName)_\(testName)"
    )
    guard let message = failure else { return }
    print(message)
    XCTFail(message, file: file, line: line)
}
