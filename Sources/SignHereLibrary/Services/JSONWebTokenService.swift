//
//  JSONWebTokenService.swift
//  Services
//
//  Created by Maxwell Elliott on 04/24/23.
//

import CoreLibrary
import Foundation
import CryptorECC

// ME: Documented here https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests

/// @mockable
internal protocol JSONWebTokenService {
    func createToken(
        keyIdentifier: String,
        issuerID: String,
        secretKey: Data
    ) throws -> String
}

internal class JSONWebTokenServiceImp: JSONWebTokenService {
    private let clock: Clock

    init(clock: Clock) {
        self.clock = clock
    }

    func createToken(
        keyIdentifier: String,
        issuerID: String,
        secretKey: Data
    ) throws -> String {
        let header: JSONWebTokenHeader = .init(
            alg: "ES256",
            typ: "JWT",
            kid: keyIdentifier
        )
        let currentTime: Date = clock.now()
        let expirationTime: Date = currentTime.addingTimeInterval(30) // ME: Tokens live for 30 seconds
        let payload: JSONWebTokenPayload = .init(
            iss: issuerID,
            iat: currentTime.timeIntervalSince1970,
            exp: expirationTime.timeIntervalSince1970,
            aud: "appstoreconnect-v1"
        )
        let jsonEncoder: JSONEncoder = .init()
        var components: [String] = [
            urlBase64Encode(data: try jsonEncoder.encode(header)),
            ".",
            urlBase64Encode(data: try jsonEncoder.encode(payload)),
        ]
        let signature: String = try createSignedHeaderPayload(data: Data(components.joined().utf8), secretKey: secretKey)
        components.append(contentsOf: [
            ".",
            signature
        ])
        return components.joined()
    }

    private func createSignedHeaderPayload(data: Data, secretKey: Data) throws -> String {
        guard let keyString = String(data: secretKey, encoding: .utf8) else {
            fatalError()
        }
        let privateKey: ECPrivateKey = try .init(key: keyString)
        guard privateKey.curve == .prime256v1
        else {
            fatalError()
        }
        let signedData: ECSignature = try data.sign(with: privateKey)
        return urlBase64Encode(data: signedData.r + signedData.s)
    }

    private func urlBase64Encode(data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
