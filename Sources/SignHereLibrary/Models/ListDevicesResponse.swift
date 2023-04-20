//
//  ListDevicesResponse.swift
//  iTunesConnectLibrary
//
//  Created by Maxwell Elliott on 04/04/23.
//

import Foundation

internal struct ListDevicesResponse: Codable {
    internal struct Device: Codable {
        internal struct Attributes: Codable {
            var deviceClass: String
            var model: String?
            var name: String
            var platform: String
            var status: String
            var udid: String
            var addedDate: Date
        }

        var id: String
        var type: String
        var attributes: Attributes
    }

    internal struct ListDevicesPagedDocumentLinks: Codable {
        var next: String?
        var `self`: String
    }

    var data: [Device]
    var links: ListDevicesPagedDocumentLinks
}
