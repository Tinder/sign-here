//
//  iTunesConnectService.swift
//  Services
//
//  Created by Maxwell Elliott on 04/05/23.
//

import CoreLibrary
import Foundation
import PathKit

/// @mockable
internal protocol iTunesConnectService {

    func fetchActiveCertificates(
        jsonWebToken: String,
        opensslPath: String,
        privateKeyPath: String,
        certificateType: String
    ) throws -> [DownloadCertificateResponse.DownloadCertificateResponseData]
    func createCertificate(
        jsonWebToken: String,
        csr: Path,
        certificateType: String
    ) throws -> CreateCertificateResponse
    func determineBundleIdITCId(
        jsonWebToken: String,
        bundleIdentifier: String,
        bundleIdentifierName: String?,
        platform: String
    ) throws -> String
    func fetchITCDeviceIDs(jsonWebToken: String) throws -> Set<String>
    func createProfile(
        jsonWebToken: String,
        bundleId: String,
        certificateId: String,
        deviceIDs: Set<String>,
        profileType: String,
        profileName: String?
    ) throws -> CreateProfileResponse
    func deleteProvisioningProfile(
        jsonWebToken: String,
        id: String
    ) throws
    func fetchProvisioningProfile(
        jsonWebToken: String,
        name: String
    ) throws -> [ProfileResponseData]
}

internal class iTunesConnectServiceImp: iTunesConnectService {
    enum Error: Swift.Error, CustomStringConvertible {
        case invalidURL(string: String)
        case unableToCreateURL(urlComponents: URLComponents)
        case unableToDetermineITCIdForBundleId(bundleIdentifier: String, platform: String)
        case unableToDetermineModulusForCertificate(output: ShellOutput)
        case unableToDetermineModulusForPrivateKey(privateKeyPath: String, output: ShellOutput)
        case unableToBase64DecodeCertificate(displayName: String)
        case unableToDeleteProvisioningProfile(id: String, responseData: Data)
        case unableToDecodeResponse(responseData: Data, decodingError: DecodingError)

        var description: String {
            switch self {
                case let .invalidURL(string: string):
                    return """
                    [iTunesConnectServiceImp] Invalid url
                    - url string: \(string)
                    """
                case let .unableToCreateURL(urlComponents: urlComponents):
                    return """
                    [iTunesConnectServiceImp] Unable to create url for itunes connect request from url components: \(urlComponents.description)
                    """
                case let .unableToDetermineITCIdForBundleId(bundleIdentifier: bundleIdentifier, platform: platform):
                    return """
                    [iTunesConnectServiceImp] Unable to determine iTunesConnect API ID for bundle identifier
                    - Bundle Identifier: \(bundleIdentifier)
                    - Platform: \(platform)
                    """
                case let .unableToDetermineModulusForCertificate(output: output):
                    return """
                    [iTunesConnectServiceImp] Unable to determine modulus for certificate
                    - Output: \(output.outputString)
                    - Error: \(output.errorString)
                    """
                case let .unableToDetermineModulusForPrivateKey(privateKeyPath: privateKeyPath, output: output):
                    return """
                    [iTunesConnectServiceImp] Unable to determine modulus for private key
                    - Private Key: \(privateKeyPath)
                    - Output: \(output.outputString)
                    - Error: \(output.errorString)
                    """
                case let .unableToBase64DecodeCertificate(displayName: displayName):
                    return """
                    [iTunesConnectServiceImp] Unable to base 64 decode certificate
                    - Certificate display name: \(displayName)
                    """
                case let .unableToDeleteProvisioningProfile(id: id, responseData: responseData):
                    return """
                    [iTunesConnectServiceImp] Unable to delete provisioning profile
                    - id: \(id)
                    - Response: \(String(data: responseData, encoding: .utf8) ?? "unknown")
                    """
                case let .unableToDecodeResponse(responseData: responseData, decodingError: decodingError):
                    return """
                    [iTunesConnectServiceImp] Unable to decode response
                    - Decoding Error: \(decodingError)
                    - Response: \(String(data: responseData, encoding: .utf8) ?? "unknown")
                    """
            }
        }
    }

    private enum Constants {
        static let applicationJSONHeaderValue: String = "application/json"
        static let contentTypeHeaderName: String = "Content-Type"
        static let httpsScheme: String = "https"
        static let itcHost: String = "api.appstoreconnect.apple.com"
        static let enterpriseHost: String = "api.enterprise.developer.apple.com"
    }

    private let network: Network
    private let files: Files
    private let shell: Shell
    private let clock: Clock
    private let enterprise: Bool

    init(
        network: Network,
        files: Files,
        shell: Shell,
        clock: Clock,
        enterprise: Bool
    ) {
        self.network = network
        self.files = files
        self.shell = shell
        self.clock = clock
        self.enterprise = enterprise
    }

    convenience init(
        enterprise: Bool
    ) {
        self.init(
            network: NetworkImp(),
            files: FilesImp(),
            shell: ShellImp(),
            clock: ClockImp(),
            enterprise: enterprise
        )
    }

    func fetchActiveCertificates(
        jsonWebToken: String,
        opensslPath: String,
        privateKeyPath: String,
        certificateType: String
    ) throws -> [DownloadCertificateResponse.DownloadCertificateResponseData] {
        let currentDate: Date = clock.now()
        let url: URL = try createRequestURL(
            path: "/v1/certificates",
            queryItems: [
                .init(name: "filter[certificateType]", value: certificateType),
                .init(name: "limit", value: "200")
            ]
        )
        var certificatesData: [DownloadCertificateResponse.DownloadCertificateResponseData] = []
        var request: URLRequest = .init(url: url)
        request.setValue("Bearer \(jsonWebToken)", forHTTPHeaderField: "Authorization")
        let jsonDecoder: JSONDecoder = createITCApiJSONDecoder()
        let data: Data = try network.execute(request: request)
        do {
            var response: DownloadCertificateResponse = try jsonDecoder.decode(
                DownloadCertificateResponse.self,
                from: data
            )
            certificatesData = response.data
            while let next: String = response.links.next,
                let nextURL: URL = .init(string: next) {
                response = try performPagedRequest(
                    url: nextURL,
                    jsonWebToken: jsonWebToken
                )
                certificatesData.append(contentsOf: response.data)
            }
            guard !certificatesData.isEmpty
            else {
                return []
            }
        } catch let decodingError as DecodingError {
            throw Error.unableToDecodeResponse(responseData: data, decodingError: decodingError)
        }
        let privateKeyModulus: String = try determinePrivateKeyModulus(opensslPath: opensslPath, privateKeyPath: privateKeyPath)
        return try certificatesData
            .filter { certificateData in
                certificateData.attributes.expirationDate > currentDate
            }
            .filter { certificateData in
                try certificateMatchesPrivateKey(
                    certificateData: certificateData,
                    privateKeyModulus: privateKeyModulus,
                    opensslPath: opensslPath
                )
            }
    }

    func createCertificate(
        jsonWebToken: String,
        csr: Path,
        certificateType: String
    ) throws -> CreateCertificateResponse {
        let url: URL = try createRequestURL(
            path: "/v1/certificates"
        )
        var request: URLRequest = .init(url: url)
        request.setValue("Bearer \(jsonWebToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            CreateCertificateRequest(
                data: .init(
                        attributes: .init(
                            certificateType: certificateType,
                            csrContent: try files.read(csr)
                        ),
                        type: "certificates"
                    )
            )
        )
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: "Accept")
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: Constants.contentTypeHeaderName)
        request.httpMethod = "POST"
        let data: Data = try network.execute(request: request)
        do {
            return try createITCApiJSONDecoder().decode(
                CreateCertificateResponse.self,
                from: data
            )
        } catch let decodingError as DecodingError {
            throw Error.unableToDecodeResponse(responseData: data, decodingError: decodingError)
        }
    }

    func determineBundleIdITCId(
        jsonWebToken: String,
        bundleIdentifier: String,
        bundleIdentifierName: String?,
        platform: String
    ) throws -> String {
        let url: URL = try createRequestURL(
            path: "/v1/bundleIds",
            queryItems: [
                .init(name: "filter[identifier]", value: bundleIdentifier),
                .init(name: "filter[platform]", value: "IOS"),
                .init(name: "limit", value: "200")
            ]
        )
        var request: URLRequest = .init(url: url)
        request.setValue("Bearer \(jsonWebToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: "Accept")
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: Constants.contentTypeHeaderName)
        request.httpMethod = "GET"
        let data: Data = try network.execute(request: request)
        return try makeFirstITCIdForBundleId(
            data: data,
            bundleIdentifier: bundleIdentifier,
            bundleIdentifierName: bundleIdentifierName,
            platform: platform
        )
    }

    private func makeFirstITCIdForBundleId(
        data: Data,
        bundleIdentifier: String,
        bundleIdentifierName: String?,
        platform: String
    ) throws -> String {
        do {
            let listBundleIDsResponse: ListBundleIDsResponse = try createITCApiJSONDecoder().decode(ListBundleIDsResponse.self, from: data)
            guard let bundleIdITCId: String = listBundleIDsResponse.data.compactMap({ bundleData in
                guard bundleData.attributes.identifier == bundleIdentifier
                else {
                    return nil
                }
                if let bundleIdentifierName: String = bundleIdentifierName {
                    guard bundleIdentifierName == bundleData.attributes.name
                    else {
                        return nil
                    }
                }
                return bundleData.id
            }).first
            else {
                throw Error.unableToDetermineITCIdForBundleId(
                    bundleIdentifier: bundleIdentifier,
                    platform: platform
                )
            }
            return bundleIdITCId
        } catch let decodingError as DecodingError {
            throw Error.unableToDecodeResponse(responseData: data, decodingError: decodingError)
        }
    }

    func fetchITCDeviceIDs(jsonWebToken: String) throws -> Set<String> {
        let url: URL = try createRequestURL(
            path: "/v1/devices",
            queryItems: [
                .init(name: "filter[status]", value: "ENABLED"),
                .init(name: "filter[platform]", value: "IOS"),
                .init(name: "limit", value: "200")
            ]
        )
        var request: URLRequest = .init(url: url)
        request.setValue("Bearer \(jsonWebToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: "Accept")
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: Constants.contentTypeHeaderName)
        request.httpMethod = "GET"
        let jsonDecoder: JSONDecoder = createITCApiJSONDecoder()
        let data: Data = try network.execute(request: request)
        do {
            var response: ListDevicesResponse = try jsonDecoder.decode(
                ListDevicesResponse.self,
                from: data
            )
            var deviceData: [ListDevicesResponse.Device] = response.data
            while let next: String = response.links.next,
                let nextURL: URL = .init(string: next) {
                response = try performPagedRequest(url: nextURL, jsonWebToken: jsonWebToken)
                deviceData.append(contentsOf: response.data)
            }
            return .init(deviceData.map { device in
                device.id
            })
        } catch let decodingError as DecodingError {
            throw Error.unableToDecodeResponse(responseData: data, decodingError: decodingError)
        }
    }

    private func performPagedRequest<T: Decodable>(url: URL, jsonWebToken: String) throws -> T {
        var pagedRequest: URLRequest = .init(url: url)
        pagedRequest.setValue("Bearer \(jsonWebToken)", forHTTPHeaderField: "Authorization")
        let jsonDecoder: JSONDecoder = createITCApiJSONDecoder()
        let data: Data = try network.execute(request: pagedRequest)
        do {
            return try jsonDecoder.decode(
                T.self,
                from: data
            )
        } catch let decodingError as DecodingError {
            throw Error.unableToDecodeResponse(responseData: data, decodingError: decodingError)
        }
    }

    func createProfile(
        jsonWebToken: String,
        bundleId: String,
        certificateId: String,
        deviceIDs: Set<String>,
        profileType: String,
        profileName: String? = nil
    ) throws -> CreateProfileResponse {
        let url: URL = try createRequestURL(
            path: "/v1/profiles"
        )
        var request: URLRequest = .init(url: url)
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: "Accept")
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: Constants.contentTypeHeaderName)
        request.setValue("Bearer \(jsonWebToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let profileName = profileName ?? "\(certificateId)_\(profileType)_\(clock.now().timeIntervalSince1970)"
        var devices: CreateProfileRequest.CreateProfileRequestData.Relationships.Devices? = nil
        // ME: App Store profiles cannot use UDIDs
        if ProfileType(rawValue: profileType).usesDevices {
            devices = .init(
                data: deviceIDs.sorted().map {
                    CreateProfileRequest.CreateProfileRequestData.Relationships.Devices.DevicesData(
                        id: $0,
                        type: "devices"
                    )
                }
            )
        }
        request.httpBody = try JSONEncoder().encode(CreateProfileRequest(
            data: .init(
                attributes: .init(
                    name: profileName,
                    profileType: profileType
                ),
                relationships: .init(
                    bundleId: .init(
                        data: .init(
                            id: bundleId,
                            type: "bundleIds"
                        )
                    ),
                    certificates: .init(
                        data: [
                            .init(
                                id: certificateId,
                                type: "certificates"
                            )
                        ]
                    ),
                    devices: devices
                ),
                type: "profiles"
            )
        ))
        let jsonDecoder: JSONDecoder = createITCApiJSONDecoder()
        let data: Data = try network.execute(request: request)
        do {
            return try jsonDecoder.decode(
                CreateProfileResponse.self,
                from: data
            )
        } catch let decodingError as DecodingError {
            throw Error.unableToDecodeResponse(responseData: data, decodingError: decodingError)
        }
    }

    func deleteProvisioningProfile(
        jsonWebToken: String,
        id: String
    ) throws {
        let url: URL = try createRequestURL(
            path: "/v1/profiles/\(id)"
        )
        var request: URLRequest = .init(url: url)
        request.setValue("Bearer \(jsonWebToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: "Accept")
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: Constants.contentTypeHeaderName)
        request.httpMethod = "DELETE"
        let tuple: (data: Data, _, statusCode: Int) = try network.executeWithStatusCode(request: request)
        guard tuple.statusCode == 204
        else {
            throw Error.unableToDeleteProvisioningProfile(id: id, responseData: tuple.data)
        }
    }

    func fetchProvisioningProfile(
        jsonWebToken: String,
        name: String
    ) throws -> [ProfileResponseData] {
        let url: URL = try createRequestURL(
            path: "/v1/profiles",
            queryItems: [
                .init(name: "filter[name]", value: name),
                .init(name: "include", value: "devices")
            ]
        )
        var request: URLRequest = .init(url: url)
        request.setValue("Bearer \(jsonWebToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: "Accept")
        request.setValue(Constants.applicationJSONHeaderValue, forHTTPHeaderField: Constants.contentTypeHeaderName)
        request.httpMethod = "GET"
        let jsonDecoder: JSONDecoder = createITCApiJSONDecoder()
        let data: Data = try network.execute(request: request)
        do {
            return try jsonDecoder.decode(
                GetProfilesResponse.self,
                from: data
            ).data
        } catch let decodingError as DecodingError {
            throw Error.unableToDecodeResponse(responseData: data, decodingError: decodingError)
        }
    }

    private func createRequestURL(
        path: String,
        queryItems: [URLQueryItem] = []
    ) throws -> URL {
        let host: String = enterprise ? Constants.enterpriseHost : Constants.itcHost
        var urlComponents: URLComponents = .init()
        urlComponents.scheme = Constants.httpsScheme
        urlComponents.host = host
        urlComponents.path = path
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        guard let url: URL = urlComponents.url
        else {
            throw Error.unableToCreateURL(urlComponents: urlComponents)
        }
        return url
    }

    private func createITCApiJSONDecoder() -> JSONDecoder {
        let jsonDecoder: JSONDecoder = .init()
        let dateFormatter: DateFormatter = .init()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        return jsonDecoder
    }

    private func certificateMatchesPrivateKey(
        certificateData: DownloadCertificateResponse.DownloadCertificateResponseData,
        privateKeyModulus: String,
        opensslPath: String
    ) throws -> Bool {
        let temporaryCerPath: Path = try files.uniqueTemporaryPath() + "validate_private_key.cer"
        guard let data: Data = .init(base64Encoded: certificateData.attributes.certificateContent)
        else {
            throw Error.unableToBase64DecodeCertificate(displayName: certificateData.attributes.displayName)
        }
        try files.write(data, to: temporaryCerPath)
        defer {
            try? files.delete(temporaryCerPath)
        }
        let output: ShellOutput = shell.execute([
            opensslPath,
            "x509",
            "-inform",
            "der",
            "-noout",
            "-modulus",
            "-in",
            temporaryCerPath.string
        ])
        guard output.isSuccessful
        else {
            throw Error.unableToDetermineModulusForCertificate(
                output: output
            )
        }
        return output.outputString.trimmingCharacters(in: .newlines) == privateKeyModulus
    }

    private func determinePrivateKeyModulus(opensslPath: String, privateKeyPath: String) throws -> String {
        let output: ShellOutput = shell.execute([
            opensslPath,
            "rsa",
            "-noout",
            "-modulus",
            "-in",
            privateKeyPath
        ])
        guard output.isSuccessful
        else {
            throw Error.unableToDetermineModulusForPrivateKey(
                privateKeyPath: privateKeyPath,
                output: output
            )
        }
        return output.outputString.trimmingCharacters(in: .newlines)
    }
}
