//
//  CertificatesModelTests.swift
//  Models
//
//  Created by Caleb Davis on 06/21/23.
//

@testable import SignHereLibrary
import XCTest

final class CertificatesModelTests: XCTestCase {
    func testCertificateType_rawValue() {
        XCTAssertEqual(CertificateType.iOSDevelopment.rawValue, "IOS_DEVELOPMENT")
        XCTAssertEqual(CertificateType.iOSDistribution.rawValue, "IOS_DISTRIBUTION")
        XCTAssertEqual(CertificateType.macAppDistribution.rawValue, "MAC_APP_DISTRIBUTION")
        XCTAssertEqual(CertificateType.macInstallerDistribution.rawValue, "MAC_INSTALLER_DISTRIBUTION")
        XCTAssertEqual(CertificateType.macAppDevelopment.rawValue, "MAC_APP_DEVELOPMENT")
        XCTAssertEqual(CertificateType.developerIdKext.rawValue, "DEVELOPER_ID_KEXT")
        XCTAssertEqual(CertificateType.developerIdApplication.rawValue, "DEVELOPER_ID_APPLICATION")
        XCTAssertEqual(CertificateType.development.rawValue, "DEVELOPMENT")
        XCTAssertEqual(CertificateType.distribution.rawValue, "DISTRIBUTION")
        XCTAssertEqual(CertificateType.passTypeId.rawValue, "PASS_TYPE_ID")
        XCTAssertEqual(CertificateType.passTypeIdWithNFC.rawValue, "PASS_TYPE_ID_WITH_NFC")
    }
}
