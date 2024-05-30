//
//  CreateProfileResponse.swift
//  Models
//
//  Created by Omar Zuniga on 29/05/24.
//

import Foundation

struct ProfileResponseData: Codable {
    struct Attributes: Codable {
        var profileContent: String
        var uuid: String
        var name: String
        var platform: String
        var createdDate: Date
        var profileState: String
        var profileType: String
        var expirationDate: Date
    }
    struct Relationships: Codable {
        struct Devices: Codable {
            struct Data: Codable {
                var id: String
                var type: String
            }

            var data: [Data]
        }
        var devices: Devices
    }
    var id: String
    var type: String
    var attributes: Attributes
    var relationships: Relationships
}