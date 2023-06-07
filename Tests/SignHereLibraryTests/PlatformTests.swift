import Foundation
import XCTestCase

final class PlatformTests: XCTestCase {
    func test_rawValue() {
        XCTAssertEqual(Platform.iOS.rawValue, "IOS")
        XCTAssertEqual(Platform.macOS.rawValue, "MAC_OS")
    }
}
