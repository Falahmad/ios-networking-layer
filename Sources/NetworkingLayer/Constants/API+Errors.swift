//
//  API+Errors.swift
//  Justdeliver
//
//  Created by Fahed Al-Ahmad on 7/17/19.
//  Copyright © 2019 JustcleanPOS. All rights reserved.
//

import Foundation

public final class APIError: Error, Sendable {
    
    public enum APIErrorCodes: CaseIterable, Sendable {
        case message
        case internetConnection
       // HTTP ERROR
        case badResuest
        case unauthorized
        case paymentRequired
        case forbidden
        case pageNotFound
        case methodNotAllowed
        case notAccepted
        case proxyAuthenticationRequired
        case requestTimeout
        case conflict
        case internalServerError
        case notImplemented
        case badGateway
        case serviceUnavailable
        case gatewayTimeout
       // SWIFT ERROR
        case APIRequest
        case taskError
        case requestFailed
        case invalidData
        case invalidJsonData
        case jsonParsingFailure
        case jsonParsingMessageFailure
        case responseUnsuccessful
        case imagePathRequired
        case unexpectedError
        case internalError
        
        var code: Int? {
            switch self {
            case .message: return nil
            case .internetConnection: return nil
            case .badResuest: return 400
            case .unauthorized: return 401
            case .paymentRequired: return 402
            case .forbidden: return 403
            case .pageNotFound: return 404
            case .methodNotAllowed: return 405
            case .notAccepted: return 406
            case .proxyAuthenticationRequired: return 407
            case .requestTimeout: return 408
            case .conflict: return 409
            case .internalServerError: return 500
            case .notImplemented: return 501
            case .badGateway: return 502
            case .serviceUnavailable: return 503
            case .gatewayTimeout: return 502
            default: return nil
            }
        }
    }
    
    private let defaultErrorMessage: String = "Sorry, we could not complete the request. Please check your internet connection or reach out to Jusclean contact"
    public let message: String?
    
    public let error: APIErrorCodes
    
    public var localizedDescription: String {
        guard let message else {
            var errMessage = defaultErrorMessage
            switch error {
           //HTTP Error
            case .badResuest: errMessage = "Bad Request"
            case .unauthorized: errMessage = "Unauthorized"
            case .paymentRequired: errMessage = "Payment required"
            case .forbidden: errMessage = "Forbidden"
            case .pageNotFound: errMessage = "Not Found"
            case .methodNotAllowed: errMessage = "Method Not Allowed"
            case .notAccepted: errMessage = "Not Acceptable"
            case .proxyAuthenticationRequired: errMessage = "Proxy Authentication Required"
            case .requestTimeout: errMessage = "Request Timeout"
            case .conflict: errMessage = "Conflict"
            case .internalServerError: errMessage = "InternalServerError"
            case .notImplemented: errMessage = "NotImplemented"
            case .badGateway: errMessage = "BadGateway"
            case .serviceUnavailable: errMessage = "ServiceUnavailable"
            case .gatewayTimeout: errMessage = "GatewayTimeout"
           // SWIFT ERROR
            case .APIRequest: errMessage = "Check API Requests"
            case .taskError: errMessage = "Task Error"
            case .requestFailed: errMessage = "Request Failed"
            case .internetConnection: errMessage = "No internet connection"
            case .responseUnsuccessful: errMessage = "Response Unsuccessful"
            case .invalidData: errMessage = "Invalid Data"
            case .invalidJsonData: errMessage = "Invalid JSON data"
            case .jsonParsingFailure: errMessage = "JSON Parsing Failure"
            case .jsonParsingMessageFailure: errMessage = "JSON Parsing Message Failure"
            case .unexpectedError: errMessage = "Unexpected Error"
            case .imagePathRequired: errMessage = "Image path is required"
            case .internalError: errMessage = "Internal error"
            default: return defaultErrorMessage
            }
            print(errMessage)
            return defaultErrorMessage
        }
        return message
    }
    
    public init() {
        message = defaultErrorMessage
        error = .internalError
    }
    
    public init(
        _ statusCode: Int,
        with message: String? = nil,
        setMessage: (( _ message: inout String?, _ error: APIErrorCodes) -> Void)? = nil
    ) {
        var error: APIErrorCodes!
        if let statusCodError = APIErrorCodes.allCases.first(where: {$0.code == statusCode}) {
            error = statusCodError
        } else {
            error = .internalError
        }
        self.error = error
        var customMessage: String?
        setMessage?(&customMessage, error)
        self.message = customMessage ?? message
    }
    
    public init(
        _ error: APIErrorCodes,
        with message: String? = nil,
        setMessage: (( _ message: inout String?, _ error: APIErrorCodes) -> Void)? = nil
    ) {
        var customMessage: String?
        setMessage?(&customMessage, error)
        self.message = customMessage ?? message
        self.error = error
    }
}
