//
//  API+Result+Logic.swift
//  JustDeliver
//
//  Created by Fahed Al-Ahmad on 1/26/20.
//

import Foundation

public struct RandomDecodableObjc: Decodable, Sendable { }
public struct EmptyResponse: Decodable, Sendable { }
public struct TokenResponse: Decodable, Sendable {
    let token: String
}

public struct PageInfo: Decodable, Sendable {
    var pageCount: Int?
    var currentPage: Int?
    var nextPage: Int?
    var itemCount: Int?
    var totalItemsCount: Int?
}

public protocol APIResponseProtocol: Decodable, Sendable {
    associatedtype DecodeType where DecodeType: Decodable & Sendable
    
    var code: Int { get set }
    var isError: Bool? { get set }
    var message: String? { get set }
    var data: DecodeType? { get set }
    var additionalData: [String: AdditionalDataValue]? { get set } // Replaced `Any?` with a dictionary
    var pageInfo: PageInfo? { get set }
}

public enum AdditionalDataValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

public enum APIResult2<T: Sendable, U: Sendable>: Sendable where T: APIResponseProtocol, U: Error  {
    case success(T)
    case failure(U)
}

public enum CustomRequestType: Sendable {
    case zammad
}
