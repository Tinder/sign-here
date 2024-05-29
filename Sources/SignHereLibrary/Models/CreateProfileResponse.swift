//
//  CreateProfileResponse.swift
//  Models
//
//  Created by Maxwell Elliott on 04/04/23.
//

import Foundation

internal struct CreateProfileResponse: Codable {
    var data: ProfileResponseData
}

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
    var id: String
    var type: String
    var attributes: Attributes
}