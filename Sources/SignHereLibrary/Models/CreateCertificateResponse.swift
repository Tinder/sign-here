//
//  CreateCertificateResponse.swift
//  iTunesConnectLibrary
//
//  Created by Maxwell Elliott on 03/31/23.
//

import Foundation

internal struct CreateCertificateResponse: Codable {
    struct CreateCertificateData: Codable {
        struct CreateCertificateResponseAttributes: Codable {
            var certificateContent: String
            var displayName: String
            var name: String
            var certificateType: String
            var serialNumber: String
        }

        var id: String
        var type: String
        var attributes: CreateCertificateResponseAttributes
    }

    var data: CreateCertificateData
}
