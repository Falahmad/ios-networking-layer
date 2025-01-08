//
//  APIRouter.swift
//  NetworkingLayer
//
//  Copyright © 2018 Fahed Alahmad. All rights reserved.
//

import Foundation
import UIKit
import AdSupport
import Combine
import Security
import CommonCrypto
import CryptoKit

final public class APIRoute: NSObject, @unchecked Sendable, APIConfigurationProtocol {
    
    public static let shared: APIRoute = .init()
    
    struct FBAPIPublicKey: Codable {
        static let key = "api_public_key"
        
        struct PKIos: Codable {
            let v3: String
            let v4: String
        }
        
        let ios: PKIos
    }
    
    typealias ApiPublickKey = (v3: String, v4: String)
    
    public var appURL: String?
    public var APIURL: String?
    public var APINestURL: String?
    public var APIKey: String?
    public var APIApplicationVersion: String?
    public var applicationVersionWithBuild: String?
    public var applicationVersion: String?
    
    private var userToken: String?
    private var countryId: Int?
    private(set) var apiPublicKeys: [String]?
    
    let rsa2048Asn1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]
    var operationQueue: OperationQueue
    var operations: [Operation] = [Operation]()
    var anyCancellable = Set<AnyCancellable>()
    
    private override init() {
        operationQueue = OperationQueue()
    }
    
    public func setup(
        appURL: String?,
        APIURL: String?,
        APINestURL: String?,
        APIKey: String?,
        APIApplicationVersion: String?,
        applicationVersionWithBuild: String?,
        applicationVersion: String?
    ) {
        self.appURL = appURL
        self.APIURL = APIURL
        self.APINestURL = APINestURL
        self.APIKey = APIKey
        self.APIApplicationVersion = APIApplicationVersion
        self.applicationVersionWithBuild = applicationVersionWithBuild
        self.applicationVersion = applicationVersion
    }
    
    public func setApiPublicKey(_ value: [String]) {
        apiPublicKeys = value
    }
    
    public func initRequest(
        isPhoto: Bool = false,
        APIRequest: APIRequests
    ) throws -> URLRequest {
        var request: URLRequest
        // URL
        var urlComponent: URLComponents!
        if let domain = APIRequest.domain {
            urlComponent = URLComponents(string: domain)
            let queryItems = APIRequest.getQueryItems()
            if !queryItems.isEmpty {
                urlComponent.queryItems = queryItems
            }
        } else if isPhoto, let appURL = self.appURL, let compnent = URLComponents(string: appURL) {
            urlComponent = compnent
        } else if !isPhoto {
            func getUrlComponent() -> URLComponents? {
                switch APIRequest.apiVersion {
                case .user:
                    if let APIURL = self.APIURL {
                        return URLComponents(string: APIURL)
                    }
                case .nest:
                    if let APINestURL = self.APINestURL {
                        return URLComponents(string: APINestURL)
                    }
                default:
                    if let APIURL = self.APIURL {
                        return URLComponents(string: APIURL)
                    }
                }
                return nil
            }
            if let component = getUrlComponent() {
                urlComponent = component
                setupURL(&urlComponent, APIRequest)
            } else {
                throw URLError(URLError.badURL)
            }
        } else {
            throw URLError(URLError.badURL)
        }
        guard let url = urlComponent.url else {
            throw URLError(URLError.badURL)
        }
        request = URLRequest(url: url)
       // HTTP Method
        request.httpMethod = APIRequest.method.rawValue
        
       // Headers
        setRequestHeader(&request, APIRequest)
        
       // Parameters
        setupParameters(&request, APIRequest)
        
        return request
    }
    
    private func setupURL(
        _ urlComponent: inout URLComponents,
        _ APIRequest: APIRequests
    ) {
        func getApiVersion() -> String? {
            switch APIRequest.apiVersion {
            case .user: return "/v3"
            case .nest: return "/v4"
            default: return nil
            }
        }
        var path = ""
        if let apiVersion = getApiVersion() {
            path += apiVersion
        }
        path += APIRequest.generatedPath()
        urlComponent.path = path
        let queryItems = APIRequest.getQueryItems()
        if !queryItems.isEmpty {
            urlComponent.queryItems = queryItems
        }
    }
    
    private func setRequestHeader(
        _ request: inout URLRequest,
        _ APIRequest: APIRequests? = nil
    ) {
        
       // Accept type
        request.setValue(ContentType.json.getType(), forHTTPHeaderField: HTTPHeaderField.acceptType.rawValue)
        
       // Accept Encoding
        request.setValue(ContentType.json.getType(), forHTTPHeaderField: HTTPHeaderField.acceptEncoding.rawValue)
        
       // Cache
        request.setValue(
            HTTPHeaderField.cacheControlValue.rawValue,
            forHTTPHeaderField: HTTPHeaderField.cacheControl.rawValue
        )
        
        // Authentication
        if let userToken = APIRequest?.userToken {
            request.setValue(
                "Bearer \(userToken)",
                forHTTPHeaderField:
                    HTTPHeaderField.authentication.rawValue
            )
        } else if let userToken = self.userToken {
            request.setValue(
                "Bearer \(userToken)",
                forHTTPHeaderField:
                    HTTPHeaderField.authentication.rawValue
            )
        }
        request.setValue(self.APIKey, forHTTPHeaderField: HTTPHeaderField.apikey.rawValue)
        
       // Application
        request.setValue(
            APIApplicationVersion ?? applicationVersionWithBuild,
            forHTTPHeaderField: HTTPHeaderField.applicationVersion.rawValue
        )
        request.setValue(
            APIApplicationVersion ?? applicationVersionWithBuild,
            forHTTPHeaderField: "app-version"
        )
        
       // AdverstisingId
        var identifierId: String? {
            return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        }
        if let id = identifierId  {
            request.setValue(id, forHTTPHeaderField: HTTPHeaderField.advertisingId.rawValue)
            request.setValue(id, forHTTPHeaderField: HTTPHeaderField.nestedAdvertisingId.rawValue)
        } else {
            let defaultAdvertisingIdentifier = "00000000-0000-0000-0000-000000000000"
            request.setValue(defaultAdvertisingIdentifier, forHTTPHeaderField: HTTPHeaderField.advertisingId.rawValue)
            request.setValue(defaultAdvertisingIdentifier, forHTTPHeaderField: HTTPHeaderField.nestedAdvertisingId.rawValue)
        }
        var localRequest = request
        Task {
            await MainActor.run {
                if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
                    localRequest.setValue(deviceId, forHTTPHeaderField: HTTPHeaderField.deviceUUID.rawValue)
                }
                localRequest.setValue(
                    UIDevice.current.name,
                    forHTTPHeaderField: HTTPHeaderField.deviceName.rawValue
                )
            }
        }
        request = localRequest
        request.setValue("ios", forHTTPHeaderField: HTTPHeaderField.deviceType.rawValue)
        request.setValue("iOS", forHTTPHeaderField: "device-type")
        request.setValue(String(1), forHTTPHeaderField: "group_id")
        
        if let APIRequest = APIRequest {
            let headers = APIRequest.getHeaders()
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.header)
            }
        }
    }
    
    private func setupParameters(_ request: inout URLRequest, _ APIRequest: APIRequests) {
        if APIRequest.method != .get {
            if let encoded = APIRequest.getEncodedParamters() {
                if let data = try? JSONEncoder().encode(encoded){
                    request.setValue(
                        ContentType.json.getType(),
                        forHTTPHeaderField: HTTPHeaderField.contentType.rawValue
                    )
                    request.httpBody = data
                }
                return
            }
            var params: Any {
                if !APIRequest.getParameters().isEmpty {
                    return APIRequest.getParameters()
                } else if !APIRequest.getOptionalParameters().isEmpty {
                    return APIRequest.getOptionalParameters()
                } else if !APIRequest.getBulkParameters().isEmpty {
                    return APIRequest.getBulkParameters()
                }
                return [String]()
            }
            switch APIRequest.contentType {
            case .json:
               // ContentType
                request.setValue(APIRequest.contentType.getType(),forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
                request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
            case .multiPartForm where params is [String:Any?]:
                let boundary = "".generateBoundaryString()
               // ContentType
                request.setValue(APIRequest.contentType.getType(boundary),forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
                do {
                    try createBodyWithParameters(&request, parameters: params as? [String:Any?], boundary: boundary)
                } catch let err {
                    print(err)
                }
            default:
                break
            }
        } else {
           // ContentType
            request.setValue(APIRequest.contentType.getType(),forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
        }
    }
    
    private func createBodyWithParameters(
        _ request: inout URLRequest,
        parameters: [String: Any?]!,
        boundary: String
    ) throws {
        let body = NSMutableData()
        let maxIndividualFileSize: Int64 = 10 * 1024 * 1024
        let maxTotalSize: Int64 = 50 * 1024 * 1024
        guard !boundary.isEmpty else {
            throw MultipartError.invalidBoundary
        }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        for (key, value) in parameters {
            if let file = value as? FileRequest {
                guard file.fileData.count < maxIndividualFileSize else {
                    throw MultipartError.fileTooLarge(fileName: file.url?.lastPathComponent ?? "unknown", size: file.fileData.count)
                }
                body.appendString(string: "--\(boundary)\r\n")
                if file.forceToUseStringInForm, let string = file.string {
                    body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(string)\"\r\n")
                } else if let fileName = file.url {
                    body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\"\r\n")
                }
                if let mimeType = file.mimeType ?? file.url?.mimeType() {
                    body.appendString(string: "Content-Type: \(mimeType)\r\n\r\n")
                }
                guard !file.fileData.isEmpty else {
                    throw MultipartError.emptyFileData(fileName: file.url?.lastPathComponent ?? "unknown")
                }
                body.append(file.fileData)
                body.appendString(string: "\r\n")
            } else if let files = value as? [FileRequest] {
                guard !files.isEmpty else {
                    throw MultipartError.emptyFileArray(key: key)
                }
                for index in 0..<files.count {
                    let file = files[index]
                    guard file.fileData.count < maxIndividualFileSize else {
                        throw MultipartError.fileTooLarge(fileName: file.url?.lastPathComponent ?? "unknown", size: file.fileData.count)
                    }
                    body.appendString(string: "--\(boundary)\r\n")
                    if let fileName = file.url {
                        body.appendString(string: "Content-Disposition: form-data; name=\"\(key)[\(index)]\"; filename=\"\(fileName)\"\r\n")
                    }
                    if let mimeType = file.mimeType ?? file.url?.mimeType() {
                        body.appendString(string: "Content-Type: \(mimeType)\r\n\r\n")
                    }
                    guard !file.fileData.isEmpty else {
                        throw MultipartError.emptyFileData(fileName: file.url?.lastPathComponent ?? "unknown")
                    }
                    body.append(file.fileData)
                    body.appendString(string: "\r\n")
                }
            } else if let value = value {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
            guard body.length < maxTotalSize else {
                throw MultipartError.totalSizeTooLarge(size: body.length)
            }
        }
        body.appendString(string: "--\(boundary)--\r\n")
        guard body.length > 0 else {
            throw MultipartError.emptyBody
        }
        request.setValue("\(body.length)", forHTTPHeaderField: "Content-Length")
        request.httpBody = body as Data
    }
    
    public enum MultipartError: Error {
        case invalidBoundary
        case emptyFileData(fileName: String)
        case emptyFileArray(key: String)
        case emptyBody
        case fileTooLarge(fileName: String, size: Int)
        case totalSizeTooLarge(size: Int)
        case connectionLost(retryCount: Int)
    }
    
    private func sha256(data : Data) -> String {
        var keyWithHeader = Data(rsa2048Asn1Header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        keyWithHeader.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            _ = CC_SHA256(pointer.baseAddress, CC_LONG(keyWithHeader.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
}

extension APIRoute: URLSessionDelegate {
    
    @available(iOS 14.0, *)
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        if let apiPublicKeys {
//            SSLPinningManager(pinnedKeyHashes: apiPublicKeys).validate(challenge: challenge, completionHandler: completionHandler)
//            return
//        }
        completionHandler(.performDefaultHandling, nil)
    }
    
}

struct SSLPinningManager {
    private enum PinningError: Error {
        case noCertificatesFromServer
        case failedToGetPublicKey
        case failedToGetDataFromPublicKey
        case receivedWrongCertificate
    }

    private var pinnedKeyHashes: [String]
    private let rsa2048ASN1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86,
        0xF7, 0x0D, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0F, 0x00
    ]

    init(pinnedKeyHashes: [String]) {
        self.pinnedKeyHashes = pinnedKeyHashes
    }

    func validate(challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                URLCredential?) -> Void) {
        do {
            // Step 1
            let trust = try validateAndGetTrust(with: challenge)
            // Step 6
            completionHandler(.useCredential, URLCredential(trust: trust))
        } catch {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    private func validateAndGetTrust(with challenge: URLAuthenticationChallenge)
    throws -> SecTrust {
        // Step 2
        if #available(iOS 15.0, *) {
            guard let trust = challenge.protectionSpace.serverTrust,
                  let trustCertificateChain = SecTrustCopyCertificateChain(trust)
                    as? [SecCertificate],
                  !trustCertificateChain.isEmpty
            else {
                throw PinningError.noCertificatesFromServer
            }
            for serverCertificate in trustCertificateChain {
                let publicKey = try getPublicKey(for: serverCertificate)
                let publicKeyHash = try getKeyHash(of: publicKey)
                // Step 5
                if pinnedKeyHashes.contains(publicKeyHash) {
                    return trust
                }
            }
        } else {
            // Fallback on earlier versions
        }
        throw PinningError.receivedWrongCertificate
    }

    private func getPublicKey(for certificate: SecCertificate) throws -> SecKey {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        // Step 3
        let trustCreationStatus = SecTrustCreateWithCertificates(certificate,
                                                                 policy,
                                                                 &trust)

        if let trust,
           trustCreationStatus == errSecSuccess,
           let publicKey = SecTrustCopyKey(trust) {
            return publicKey
        } else {
            throw PinningError.failedToGetPublicKey
        }
    }

    private func getKeyHash(of publicKey: SecKey) throws -> String {
        guard let publicKeyCFData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
            throw PinningError.failedToGetDataFromPublicKey
        }

        // Step 4
        let publicKeyData = (publicKeyCFData as NSData) as Data
        var publicKeyWithHeaderData = Data(rsa2048ASN1Header)
        publicKeyWithHeaderData.append(publicKeyData)
        let publicKeyHashData = Data(SHA256.hash(data: publicKeyWithHeaderData))
        return publicKeyHashData.base64EncodedString()
    }
}
