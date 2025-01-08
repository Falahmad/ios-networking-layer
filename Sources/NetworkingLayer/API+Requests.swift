//
//  APIRequests.swift
//  JustDeliver
//
//  Created by Fahed Al-Ahmad on 9/9/19.
//

import Foundation

public enum APIVersion {
    case user
    case nest
    
    var version: String {
        switch self {
        case .user: return "v3"
        case .nest: return "v4"
        }
    }
}

public protocol APIRequests: Sendable {
    typealias HeaderField = (value: String, header: String)
    
    /**
    Domain modeling is the first first after the domain,
     It has to be declared so we can track path error
     */
    var domainModeling: DomainModeling { get }
    
    /**
    declare domain if the intialized api has a custom domain token
     */
    var domain: String? { get }
    
    /**
    declare APIToken if the intialized api has a custom api token
     */
    var APIToken: String? { get }
    
    /**
     The path right after the domain modeling
     */
    var path: String? { get }
    
    /**
     This is the path after domainModeling and path
     - Note:
     https://example.com/domainModelingPath/Path/fullPathAfterDomainModelingPath
     */
    var fullPathAfterDomainModelingPath: String? { get }
    /**
     This is the object id you performing that API on
     - Note:
     since fullPathAfterDomainModelingPath is optional it wont be in path generation func
     https://example.com/domainModelingPath/Path/objectIdForApi
     https://example.com/domainModelingPath/Path/fullPathAfterDomainModelingPath/objectIdForApi
     */
    var objectIdForApi: Int? { get }
    var method: HTTPMethods { get }
    var apiVersion: APIVersion? { get }
    var userToken: String? { get }
    var contentType: ContentType { get }
    var additionalData: [String: AdditionalDataValue]? { get }
    
    func getParameters() -> [String : Any]
    func getOptionalParameters() -> [String : Any?]
    func getEncodedParamters() -> Encodable?
    func getBulkParameters() -> [[String : Any]]
    func getQueryItems() -> [URLQueryItem]
    func getHeaders() -> [HeaderField]
    
    func generatedPath() -> String
    func sessionConfigAdditionalHeaders() -> [AnyHashable : Any]
}

extension APIRequests {
    
    var domain: String? { nil }
    
    var APIToken: String? { nil }
    
    var userToken: String? { nil }
    
    var contentType: ContentType { .json }
    
    var additionalData: Any? { nil }
    
    func getParameters() -> [String : Any] { [:] }
    
    func getOptionalParameters() -> [String : Any?] { [:] }
    
    func getEncodedParamters() -> Encodable? { nil }
    
    func getBulkParameters() -> [[String : Any]] { [[:]] }
    
    func getQueryItems() -> [URLQueryItem] { [] }
    
    func getHeaders() -> [HeaderField] { [] }
    
    func generatedPath() -> String {
        let filteredDomainModelingPath: String = domainModeling.path.replacingOccurrences(of: "/", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        var path: String = "/" + filteredDomainModelingPath
        
        if let filteredPath = self.path?.replacingOccurrences(of: "/", with: "").trimmingCharacters(in: .whitespacesAndNewlines) {
            path += "/" + filteredPath
        }
        
        if let fullPathAfterDomainModelingPath = fullPathAfterDomainModelingPath {
            path += "/" + fullPathAfterDomainModelingPath
        }
        
        if let objectIdForApi = objectIdForApi {
            path += "/" + String(objectIdForApi)
        }
        
        return path
    }
    
    func sessionConfigAdditionalHeaders() -> [AnyHashable : Any] { return [:] }
}
