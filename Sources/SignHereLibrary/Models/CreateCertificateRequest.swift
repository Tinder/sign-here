//
//  CreateCertificateRequest.swift
//  iTunesConnectLibrary
//
//  Created by Maxwell Elliott on 03/31/23.
//

internal struct CreateCertificateRequest: Codable {
    struct CreateCertificateRequestData: Codable {
        struct CreateCertificateRequestAttributes: Codable {
            var certificateType: String
            var csrContent: String
        }

        var attributes: CreateCertificateRequestAttributes
        var type: String
    }

    var data: CreateCertificateRequestData
}
