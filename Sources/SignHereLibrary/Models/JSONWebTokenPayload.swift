//
//  JSONWebTokenPayload.swift
//  iTunesConnectLibrary
//
//  Created by Maxwell Elliott on 03/28/23.
//

// ME: Documented here https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests

internal struct JSONWebTokenPayload: Codable {
    let iss: String
    let iat: Double
    let exp: Double
    let aud: String
}
