//
//  JSONWebTokenHeader.swift
//  iTunesConnectLibrary
//
//  Created by Maxwell Elliott on 03/28/23.
//

// ME: Documented here https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests

internal struct JSONWebTokenHeader: Codable {
    let alg: String
    let typ: String
    let kid: String
}
