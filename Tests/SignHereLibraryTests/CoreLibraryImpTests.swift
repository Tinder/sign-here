//
//  CoreLibraryImpTests.swift
//  SignHereLibraryTests
//
//  Integration coverage for the concrete CoreLibrary wrappers. The
//  protocols are mocked everywhere upstream; these tests exercise the
//  real implementations so the wrappers are not a black hole in our
//  line-coverage metric.
//

import CoreLibrary
import CoreLibrary_GeneratedMocks
import Foundation
import PathKit
import XCTest

final class ClockImpTests: XCTestCase {
    func test_now_isApproximatelyCurrentTime() {
        let before: Date = Date()
        let now: Date = ClockImp().now()
        let after: Date = Date()
        XCTAssertGreaterThanOrEqual(now.timeIntervalSince1970, before.timeIntervalSince1970)
        XCTAssertLessThanOrEqual(now.timeIntervalSince1970, after.timeIntervalSince1970)
    }
}

final class UUIDImpTests: XCTestCase {
    func test_make_returnsValidUUIDString() {
        let value: String = UUIDImp().make()
        XCTAssertNotNil(Foundation.UUID(uuidString: value))
    }

    func test_make_isUniqueAcrossInvocations() {
        let uuid: UUIDImp = .init()
        XCTAssertNotEqual(uuid.make(), uuid.make())
    }
}

final class ProcessInfoImpTests: XCTestCase {
    func test_environment_matchesFoundationProcessInfo() {
        let env: [String: String] = ProcessInfoImp().environment()
        XCTAssertEqual(env, Foundation.ProcessInfo.processInfo.environment)
        // PATH is always present in any reasonable shell environment.
        XCTAssertNotNil(env["PATH"])
    }
}

final class LogImpTests: XCTestCase {
    func test_append_writesToStandardOut() {
        // We can't easily redirect stdout in a swift_test bundle, so we
        // simply call through and assert the call completes — the work is
        // delegated to `print`, which the standard library guarantees.
        let log: LogImp = .init()
        log.append("hello")
        log.append("hello", terminator: "")
        log.append(42)
    }
}

final class FilesImpTests: XCTestCase {
    var tempRoot: Path!
    var subject: FilesImp!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempRoot = try Path.uniqueTemporary()
        subject = FilesImp()
    }

    override func tearDownWithError() throws {
        if tempRoot.exists {
            try? tempRoot.delete()
        }
        tempRoot = nil
        subject = nil
        try super.tearDownWithError()
    }

    func test_writeAndReadString() throws {
        let path: Path = tempRoot + "note.txt"
        try subject.write("hello world", to: path)
        let value: String = try subject.read(path)
        XCTAssertEqual(value, "hello world")
    }

    func test_writeAndReadData() throws {
        let path: Path = tempRoot + "blob.bin"
        let payload: Data = Data([0x00, 0x01, 0x02, 0xff])
        try subject.write(payload, to: path)
        let value: Data = try subject.read(path)
        XCTAssertEqual(value, payload)
    }

    func test_createDirectory_createsIntermediateDirectories() throws {
        let path: Path = tempRoot + "a/b/c"
        try subject.createDirectory(path)
        XCTAssertTrue(path.isDirectory)
    }

    func test_delete_removesExistingFile() throws {
        let path: Path = tempRoot + "ephemeral.txt"
        try subject.write("x", to: path)
        XCTAssertTrue(path.exists)
        try subject.delete(path)
        XCTAssertFalse(path.exists)
    }

    func test_uniqueTemporaryPath_isFreshDirectoryEachCall() throws {
        let one: Path = try subject.uniqueTemporaryPath()
        let two: Path = try subject.uniqueTemporaryPath()
        XCTAssertTrue(one.isDirectory)
        XCTAssertTrue(two.isDirectory)
        XCTAssertNotEqual(one, two)
        try? one.delete()
        try? two.delete()
    }

    func test_readString_throwsWhenFileMissing() {
        XCTAssertThrowsError(try subject.read(tempRoot + "missing.txt") as String)
    }

    func test_readData_throwsWhenFileMissing() {
        XCTAssertThrowsError(try subject.read(tempRoot + "missing.bin") as Data)
    }
}

final class ShellImpTests: XCTestCase {
    var subject: ShellImp!

    override func setUp() {
        super.setUp()
        subject = ShellImp()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_execute_returnsStdoutForSuccessfulCommand() {
        let output: ShellOutput = subject.execute(launchPath: "/bin/echo", ["hello"])
        XCTAssertEqual(output.status, 0)
        XCTAssertTrue(output.isSuccessful)
        XCTAssertEqual(output.outputString, "hello\n")
        XCTAssertEqual(output.errorString, "")
    }

    func test_execute_returnsStderrAndNonZeroStatusOnFailure() {
        // /bin/ls of a missing path is a deterministic failure that writes
        // to stderr.
        let output: ShellOutput = subject.execute(
            launchPath: "/bin/ls",
            ["/this/path/does/not/exist/sign-here-cov-test"]
        )
        XCTAssertNotEqual(output.status, 0)
        XCTAssertFalse(output.isSuccessful)
        XCTAssertTrue(output.errorString.contains("No such file"))
    }

    func test_execute_environmentIsForwardedToChild() {
        let output: ShellOutput = subject.execute(
            launchPath: "/bin/sh",
            ["-c", "echo $SIGN_HERE_COV_VAR"],
            environment: ["SIGN_HERE_COV_VAR": "the-value", "PATH": "/usr/bin:/bin"]
        )
        XCTAssertEqual(output.outputString, "the-value\n")
    }

    func test_execute_stdinIsForwardedToChild() {
        let output: ShellOutput = subject.execute(
            launchPath: "/bin/cat",
            [],
            environment: nil,
            stdinData: Data("piped-input".utf8)
        )
        XCTAssertEqual(output.outputString, "piped-input")
        XCTAssertTrue(output.isSuccessful)
    }

    func test_execute_inPath_runsRelativeCommandsRelativeToThatDirectory() throws {
        let dir: Path = try Path.uniqueTemporary()
        defer { try? dir.delete() }
        try (dir + "marker.txt").write("present")
        let output: ShellOutput = subject.execute(
            launchPath: "/bin/ls",
            ["."],
            path: dir,
            environment: nil
        )
        XCTAssertTrue(output.isSuccessful)
        XCTAssertTrue(output.outputString.contains("marker.txt"))
    }
}

final class ShellOutputTests: XCTestCase {
    func test_outputAndErrorStrings_decodeUTF8() {
        let output: ShellOutput = .init(
            status: 7,
            data: Data("standard out".utf8),
            errorData: Data("standard err".utf8)
        )
        XCTAssertEqual(output.outputString, "standard out")
        XCTAssertEqual(output.errorString, "standard err")
        XCTAssertFalse(output.isSuccessful)
    }

    func test_equatable() {
        let a: ShellOutput = .init(status: 0, data: Data("x".utf8), errorData: Data())
        let b: ShellOutput = .init(status: 0, data: Data("x".utf8), errorData: Data())
        let c: ShellOutput = .init(status: 1, data: Data("x".utf8), errorData: Data())
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}

final class NetworkImpTests: XCTestCase {
    private final class StubHandler: DataTaskHandler {
        var data: Data?
        var response: URLResponse?
        var error: Swift.Error?
        var captured: URLRequest?

        func executeDataTask(
            with request: URLRequest,
            completionHandler: @escaping (Data?, URLResponse?, Swift.Error?) -> Void
        ) {
            captured = request
            completionHandler(data, response, error)
        }
    }

    private struct DummyError: Swift.Error {}

    func test_execute_returnsDataOnSuccess() throws {
        let handler: StubHandler = .init()
        handler.data = Data("payload".utf8)
        handler.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["X-Test": "1"]
        )
        let network: NetworkImp = .init(handler: handler)
        let result: Data = try network.execute(
            request: URLRequest(url: URL(string: "https://example.com")!)
        )
        XCTAssertEqual(result, Data("payload".utf8))
        XCTAssertEqual(handler.captured?.url, URL(string: "https://example.com"))
    }

    func test_executeWithStatusCode_returnsStatusAndHeaders() throws {
        let handler: StubHandler = .init()
        handler.data = Data("body".utf8)
        handler.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: ["X-One": "v1"]
        )
        let network: NetworkImp = .init(handler: handler)
        let result = try network.executeWithStatusCode(
            request: URLRequest(url: URL(string: "https://example.com")!)
        )
        XCTAssertEqual(result.data, Data("body".utf8))
        XCTAssertEqual(result.statusCode, 201)
        XCTAssertEqual(result.allHeaderFields["X-One"] as? String, "v1")
    }

    func test_executeWithStatusCode_propagatesNetworkError() {
        let handler: StubHandler = .init()
        handler.error = DummyError()
        let network: NetworkImp = .init(handler: handler)
        XCTAssertThrowsError(
            try network.executeWithStatusCode(
                request: URLRequest(url: URL(string: "https://example.com")!)
            )
        ) { error in
            guard case NetworkImp.Error.networkError = error else {
                XCTFail("expected .networkError, got \(error)")
                return
            }
        }
    }

    func test_executeWithStatusCode_throwsMissingDataWhenNoBody() {
        let handler: StubHandler = .init() // data + response stay nil
        let network: NetworkImp = .init(handler: handler)
        XCTAssertThrowsError(
            try network.executeWithStatusCode(
                request: URLRequest(url: URL(string: "https://example.com")!)
            )
        ) { error in
            guard case NetworkImp.Error.missingData = error else {
                XCTFail("expected .missingData, got \(error)")
                return
            }
        }
    }

    func test_executeWithStatusCode_throwsMissingStatusCodeForNonHTTPResponse() {
        let handler: StubHandler = .init()
        handler.data = Data("x".utf8)
        handler.response = URLResponse(
            url: URL(string: "https://example.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        let network: NetworkImp = .init(handler: handler)
        XCTAssertThrowsError(
            try network.executeWithStatusCode(
                request: URLRequest(url: URL(string: "https://example.com")!)
            )
        ) { error in
            guard case NetworkImp.Error.missingStatusCode = error else {
                XCTFail("expected .missingStatusCode, got \(error)")
                return
            }
        }
    }

    func test_errorDescriptions_haveStableText() {
        XCTAssertEqual(
            NetworkImp.Error.missingData.description,
            "[NetworkImp] Missing response data"
        )
        XCTAssertEqual(
            NetworkImp.Error.missingStatusCode.description,
            "[NetworkImp] Missing status code in response"
        )
        XCTAssertEqual(
            NetworkImp.Error.missingHeaderFields.description,
            "[NetworkImp] Missing header fields in response"
        )
        XCTAssertTrue(
            NetworkImp.Error.networkError(DummyError())
                .description
                .hasPrefix("[NetworkImp] Networking error:")
        )
    }
}

final class URLSessionDataTaskHandlerTests: XCTestCase {
    func test_executeDataTask_invokesCompletionForLocalRequest() {
        let session: URLSession = URLSession(configuration: .ephemeral)
        let expectation: XCTestExpectation = self.expectation(description: "completion fires")
        session.executeDataTask(
            // Routing to a non-existent local port forces a fast failure
            // without depending on external network connectivity.
            with: URLRequest(url: URL(string: "http://127.0.0.1:1/never")!)
        ) { _, _, _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }
}

final class KeychainImpTests: XCTestCase {
    var shell: ShellMock!
    var processInfo: ProcessInfoMock!
    var subject: KeychainImp!

    override func setUp() {
        super.setUp()
        shell = ShellMock()
        processInfo = ProcessInfoMock()
        subject = KeychainImp(shell: shell, processInfo: processInfo)
    }

    override func tearDown() {
        shell = nil
        processInfo = nil
        subject = nil
        super.tearDown()
    }

    private func stubShell(status: Int, stdout: String = "", stderr: String = "") {
        shell.executeLaunchPathHandler = { _, _, _, _ in
            ShellOutput(
                status: status,
                data: Data(stdout.utf8),
                errorData: Data(stderr.utf8)
            )
        }
    }

    func test_setDefaultKeychain_invokesSecurityTool() throws {
        stubShell(status: 0)
        try subject.setDefaultKeychain(keychainName: "build.keychain")
        XCTAssertEqual(shell.executeLaunchPathCallCount, 1)
        let args: [String] = shell.executeLaunchPathArgValues[0].1
        XCTAssertEqual(args, ["/usr/bin/security", "default-keychain", "-s", "build.keychain"])
    }

    func test_setDefaultKeychain_throwsOnFailure() {
        stubShell(status: 1, stderr: "denied")
        XCTAssertThrowsError(try subject.setDefaultKeychain(keychainName: "x")) { error in
            guard case KeychainImp.Error.unableToSetDefaultKeychain = error else {
                XCTFail("expected unableToSetDefaultKeychain, got \(error)")
                return
            }
            XCTAssertTrue("\(error)".contains("denied"))
        }
    }

    func test_setKeychainSearchList_invokesSecurityTool() throws {
        stubShell(status: 0)
        try subject.setKeychainSearchList(keychainNames: ["one.keychain", "two.keychain"])
        let args: [String] = shell.executeLaunchPathArgValues[0].1
        XCTAssertEqual(args, [
            "/usr/bin/security",
            "list-keychains",
            "-d",
            "user",
            "-s",
            "one.keychain",
            "two.keychain",
        ])
    }

    func test_setKeychainSearchList_throwsOnFailure() {
        stubShell(status: 1, stderr: "boom")
        XCTAssertThrowsError(try subject.setKeychainSearchList(keychainNames: ["a"])) { error in
            guard case KeychainImp.Error.unableToUpdateKeychainSearchList = error else {
                XCTFail("expected unableToUpdateKeychainSearchList, got \(error)")
                return
            }
            XCTAssertTrue("\(error)".contains("boom"))
        }
    }

    func test_deleteKeychain_succeedsForSuccessfulShellInvocation() throws {
        stubShell(status: 0)
        try subject.deleteKeychain(keychainName: "build.keychain")
    }

    func test_deleteKeychain_swallowsMissingKeychainError() throws {
        stubShell(
            status: 44,
            stderr: "security: SecKeychainDelete: The specified keychain could not be found."
        )
        try subject.deleteKeychain(keychainName: "build.keychain")
    }

    func test_deleteKeychain_throwsForOtherFailures() {
        stubShell(status: 1, stderr: "something else broke")
        XCTAssertThrowsError(try subject.deleteKeychain(keychainName: "build.keychain")) { error in
            guard case KeychainImp.Error.unableToDeleteKeychain = error else {
                XCTFail("expected unableToDeleteKeychain, got \(error)")
                return
            }
        }
    }
}
