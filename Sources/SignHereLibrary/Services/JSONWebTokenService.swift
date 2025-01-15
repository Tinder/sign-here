//
//  JSONWebTokenService.swift
//  Services
//
//  Created by Maxwell Elliott on 04/24/23.
//

import CoreLibrary
import Foundation
import CryptoKit

// ME: Documented here https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests

/// @mockable
internal protocol JSONWebTokenService {
    func createToken(
        keyIdentifier: String,
        issuerID: String,
        secretKey: Data,
        enterprise: Bool
    ) throws -> String
}

internal class JSONWebTokenServiceImp: JSONWebTokenService {
    internal enum Error: Swift.Error, CustomStringConvertible {
        case unableToCreateKeyString
        case unableToCreatePrivateKey

        var description: String {
            switch self {
            case .unableToCreateKeyString:
                return "[JSONWebTokenService] Unable to create key string"
            case .unableToCreatePrivateKey:
                return "[JSONWebTokenService] Unable to create private key"
            }
        }
    }

    private let clock: Clock

    init(clock: Clock) {
        self.clock = clock
    }

    func createToken(
        keyIdentifier: String,
        issuerID: String,
        secretKey: Data,
        enterprise: Bool
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
            aud: enterprise ? "apple-developer-enterprise-v1" : "appstoreconnect-v1"
        )
        let jsonEncoder: JSONEncoder = .init()
        var components: [String] = [
            urlBase64Encode(data: try jsonEncoder.encode(header)),
            ".",
            urlBase64Encode(data: try jsonEncoder.encode(payload)),
        ]
        let signature: String = try createSignature(data: Data(components.joined().utf8), secretKey: secretKey)
        components.append(contentsOf: [
            ".",
            signature
        ])
        return components.joined()
    }

    private func createSignature(data: Data, secretKey: Data) throws -> String {
        guard let keyString = String(data: secretKey, encoding: .utf8) else {
            throw Error.unableToCreateKeyString
        }
        let key = try P256.Signing.PrivateKey(pemRepresentation: keyString)
        let signature = try key.signature(for: data)
        return urlBase64Encode(data: signature.rawRepresentation)
    }

    private func urlBase64Encode(data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
