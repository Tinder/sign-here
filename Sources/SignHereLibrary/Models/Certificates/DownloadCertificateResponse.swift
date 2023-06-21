//
//  DownloadCertificateResponse.swift
//  Models
//
//  Created by Maxwell Elliott on 03/29/23.
//

import Foundation

internal struct DownloadCertificateResponse: Codable {
    struct DownloadCertificateResponseData: Codable {
        struct DownloadCertificateResponseDataAttributes: Codable {
            var certificateContent: String
            var certificateType: CertificateType
            var expirationDate: Date
            var displayName: String
        }

        var id: String
        var attributes: DownloadCertificateResponseDataAttributes
    }

    struct PagedDocumentLinks: Codable {
        var `self`: String
        var next: String?
    }

    var data: [DownloadCertificateResponseData]
    var links: PagedDocumentLinks
}
