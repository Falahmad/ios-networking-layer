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
    Domain modeling is the first path after the domain,
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
    
    public var domain: String? { nil }
    
    public var path: String? { nil }
    
    public var fullPathAfterDomainModelingPath: String? { nil }
    
    public var objectIdForApi: Int? { nil }
    
    public var APIToken: String? { nil }
    
    public var userToken: String? { nil }
    
    public var contentType: ContentType { .json }
    
    public var apiVersion: APIVersion? { nil }
    
    public var additionalData: [String: AdditionalDataValue]? { nil }
    
    public func getParameters() -> [String : Any] { [:] }
    
    public func getOptionalParameters() -> [String : Any?] { [:] }
    
    public func getEncodedParamters() -> Encodable? { nil }
    
    public func getBulkParameters() -> [[String : Any]] { [[:]] }
    
    public func getQueryItems() -> [URLQueryItem] { [] }
    
    public func getHeaders() -> [HeaderField] { [] }
    
    public func generatedPath() -> String {
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
    
    public func sessionConfigAdditionalHeaders() -> [AnyHashable : Any] { return [:] }
}
