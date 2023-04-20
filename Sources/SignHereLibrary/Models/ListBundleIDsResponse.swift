//
//  ListBundleIDsResponse.swift
//  iTunesConnectLibrary
//
//  Created by Maxwell Elliott on 04/04/23.
//

internal struct ListBundleIDsResponse: Codable {
    struct BundleId: Codable {
        struct Attributes: Codable {
            var name: String
            var identifier: String
            var platform: String
        }

        var id: String
        var type: String
        var attributes: Attributes
    }
    var data: [BundleId]
}
