//
//  CreateProfileRequest.swift
//  iTunesConnectLibrary
//
//  Created by Maxwell Elliott on 04/04/23.
//

internal struct CreateProfileRequest: Codable {
    struct CreateProfileRequestData: Codable {
        struct Attributes: Codable {
            var name: String
            var profileType: String
        }

        struct Relationships: Codable {
            struct BundleId: Codable {
                struct BundleIdData: Codable {
                    var id: String
                    var type: String
                }
                var data: BundleIdData
            }

            struct Certificates: Codable {
                struct CertificatesData: Codable {
                    var id: String
                    var type: String
                }

                var data: [CertificatesData]
            }

            struct Devices: Codable {
                struct DevicesData: Codable {
                    var id: String
                    var type: String
                }

                var data: [DevicesData]
            }

            var bundleId: BundleId
            var certificates: Certificates
            var devices: Devices
        }

        var attributes: Attributes
        var relationships: Relationships
        var type: String
    }
    var data: CreateProfileRequestData
}
