//
//  CertificateOutput.swift
//  Commands
//
//  Created by Oscar Berggren on 2026-03-30.
//

import Foundation

internal struct CertificateOutput: Codable, Equatable {
    let selectedCertificateId: String?
    let certificateSource: CertificateSource?
    let certificates: [Certificate]

    struct Certificate: Codable, Equatable {
        let id: String
        let displayName: String
        let certificateType: String
        let expirationDate: Date
    }
}
