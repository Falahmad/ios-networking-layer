//
//  API+Headers.swift
//  Justdeliver
//
//  Created by Fahed Al-Ahmad on 7/17/19.
//  Copyright © 2019 JustcleanPOS. All rights reserved.
//

import Foundation

public enum HTTPMethods: String, Sendable {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public enum HTTPHeaderField: String, Sendable {
    case authentication = "Authorization"
    case pusherAuth = "authorizer"
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case apikey = "x-api-key"
    case cacheControl = "Cache-Control"
    case cacheControlValue = "no-cache"
    
    case applicationVersion = "app_version"
    
    case language_id = "language_id"
    case languageId = "languageId"
    case nestedLanguageId = "language-id"
    
    case country_id = "country_id"
    case countryId = "countryId"
    case nestedCountryId = "country-id"
    
    case area_id = "area_id"
    case areaId = "areaId"
    
    case deviceName = "device_name"
    case deviceToken = "device_token"
    case apnToken = "apn-token"
    case deviceUUID = "device_uuid"
    case deviceType = "device_type"
    case deviceVersion = "device_version"
    case advertisingId = "advertising_id"
    case nestedAdvertisingId = "advertising-id"
}


public enum ContentType: Sendable {
    case json
    case multiPartForm
    case form
    
    func getType(_ boundary: String? = nil) -> String {
        switch self {
        case .json:
            return "application/json"
        case .multiPartForm:
            guard let boundary = boundary else {
                print("Boundary is nil")
                return "application/x-www-form-urlencoded"
            }
            return "multipart/form-data; boundary=\(boundary)"
        case .form:
            return "application/x-www-form-urlencoded"
        }
    }
}

public enum AuthorizationTypes: String, Sendable {
    case bearer = "Bearer "
}


public struct FileRequest: Sendable {
    let fileData: Data
    let mimeType: String?
    let url: URL?
    var string: String?
    
    let forceToUseStringInForm: Bool
    
    init(
        fileData: Data,
        url: URL? = nil,
        string: String? = nil,
        forceToUseStringInForm: Bool = false
    ) {
        self.fileData = fileData
        let mimeType = fileData.getMimeType()
        self.mimeType = mimeType
        self.url = url ?? URL(string: "https://justclean.com/vehicle/\(PushIDGenerator().generate()).\(fileData.getMimeTypeExtension() ?? "")")
        self.string = string
        self.forceToUseStringInForm = forceToUseStringInForm
    }
}
