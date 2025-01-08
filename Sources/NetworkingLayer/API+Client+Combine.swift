//
//  API+Client+Combine.swift
//  justclean
//
//  Created by Fahed Al-Ahmad on 21/02/2022.
//  Copyright © 2022 Justclean. All rights reserved.
//

import Foundation
import Combine

extension APIRoute {
    
    public func combineRequest<Response>(
        request: APIRequests,
        _ response: Response.Type
    ) -> Future<Response, APIError> where Response: APIResponseProtocol {
        return Future<Response, APIError> { promise in
            #if !AppClip && !OrderWidget && !NotificationService
            guard APIReachability.isConnectedToNetwork() else {
                let internetConnectionError = APIError(.internetConnection)
                promise(.failure(internetConnectionError))
                return
            }
            #endif
            var userInfo: [String: Any] = [
                "function": #function
            ]
            do {
                let urlRequest = try self.initRequest(APIRequest: request)
                #if !AppClip && !OrderWidget && !NotificationService
//                    NonFatalError_Crashlystics.fillCrashlyticsInfo(userInfo: &userInfo, request: request, urlRequest: urlRequest)
                #endif
                
                let decoder = JSONDecoder()
                var anyCancellable = Set<AnyCancellable>()
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 60 // 60 seconds
                config.timeoutIntervalForResource = 300 // 5 minutes
                var httpAdditionalHeaders: [AnyHashable : Any] = [:]
                if let apiVersion = request.apiVersion?.version {
                    httpAdditionalHeaders.updateValue(apiVersion, forKey: "apiVersion")
                }
                let requestAdditionalHeaders = request.sessionConfigAdditionalHeaders()
                for (key, value) in requestAdditionalHeaders {
                    httpAdditionalHeaders.updateValue(value, forKey: key)
                }
                config.httpAdditionalHeaders = httpAdditionalHeaders
                
                let urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
                urlSession.dataTaskPublisher(for: urlRequest)
                    .subscribe(on: DispatchQueue.global(qos: .background))
                    .tryMap({ output in
                        do {
                            let validatingResponse = try self.tryCombineRequest(
                                urlRequest: urlRequest,
                                output: output,
                                request: request,
                                userInfo: &userInfo
                            )
                            return validatingResponse
                        } catch let err {
                            print("---------------------------------------")
                            print("---------------------------------------")
                            print("Response Error", (request.domainModeling.path+(request.path ?? "")))
                            if let response = try? JSONDecoder().decode(Response.self, from: output.data) {
                                let errMessage = response.message ?? ""
                                print("API error message", errMessage)
                                #if !AppClip && !OrderWidget && !NotificationService
                                userInfo.updateValue(errMessage, forKey: "error")
//                                NonFatalError_Crashlystics().reportNonFatalCrash(
//                                    domain: "Networking-\(urlRequest.url?.absoluteString ?? "")",
//                                    domainCode: request.domainModeling.domainCode,
//                                    userInfo: userInfo
//                                )
                                #endif
                                throw APIError.init(response.code, with: errMessage)
                            }
                            print("---------------------------------------")
                            print("---------------------------------------")
                            #if !AppClip && !OrderWidget && !NotificationService
                            userInfo.updateValue(err.localizedDescription, forKey: "error")
//                            NonFatalError_Crashlystics().reportNonFatalCrash(
//                                domain: "Networking-\(urlRequest.url?.absoluteString ?? "")",
//                                domainCode: request.domainModeling.domainCode,
//                                userInfo: userInfo
//                            )
                            #endif
                            throw err
                        }
                    })
                    .decode(type: Response.self, decoder: decoder)
                    .tryMap({ response in
                        var response = response
                        if (response.isError ?? false), let message = response.message {
                            print("---------------------------------------")
                            print("---------------------------------------")
                            print("API Error in:", (request.domainModeling.path+(request.path ?? "")))
                            print(message)
                            print("---------------------------------------")
                            print("---------------------------------------")
                            #if !AppClip && !OrderWidget && !NotificationService
                            userInfo.updateValue(message, forKey: "error")
//                            NonFatalError_Crashlystics().reportNonFatalCrash(
//                                domain: "Networking-\(urlRequest.url?.absoluteString ?? "")",
//                                domainCode: request.domainModeling.domainCode,
//                                userInfo: userInfo
//                            )
                            #endif
                            throw APIError.init(response.code, with: message)
                        }
                        response.additionalData = request.additionalData
                        return response
                    })
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let err):
                            #if !AppClip && !OrderWidget && !NotificationService
                            userInfo.updateValue(err.localizedDescription, forKey: "error")
//                            NonFatalError_Crashlystics().reportNonFatalCrash(
//                                domain: "Networking-\(urlRequest.url?.absoluteString ?? "")",
//                                domainCode: request.domainModeling.domainCode,
//                                userInfo: userInfo
//                            )
                            #endif
                            if let error = err as? APIError {
                                promise(.failure(error))
                            } else {
                                promise(.failure(.init(.internalError, with: err.localizedDescription)))
                            }
                        }
                    }, receiveValue: { result in
                        promise(.success(result))
                    })
                    .store(in: &anyCancellable)
            } catch let err {
                let apiRequestError = APIError(.APIRequest, with: err.localizedDescription)
                userInfo.updateValue(apiRequestError.localizedDescription, forKey: "error")
                userInfo.updateValue("Request creation", forKey: "from")
                #if !AppClip && !OrderWidget && !NotificationService
//                NonFatalError_Crashlystics().reportNonFatalCrash(
//                    domain: "Networking-\(request.generatedPath())",
//                    domainCode: request.domainModeling.domainCode,
//                    userInfo: userInfo
//                )
                #endif
                promise(.failure(apiRequestError))
            }
        }
    }
    
    public func customCombineRequest<Response>(
        request: APIRequests,
        _ response: Response.Type,
        customRequestType: CustomRequestType? = nil
    ) -> Future<Response, APIError> where Response: Codable {
        return Future<Response, APIError> { promise in
            #if !AppClip && !OrderWidget && !NotificationService
            guard APIReachability.isConnectedToNetwork() else {
                let internetConnectionError = APIError(.internetConnection)
                promise(.failure(internetConnectionError))
                return
            }
            #endif
            var userInfo: [String: Any] = [
                "function": #function
            ]
            do {
                let urlRequest = try self.initRequest(APIRequest: request)
                #if !AppClip && !OrderWidget && !NotificationService
//                    NonFatalError_Crashlystics.fillCrashlyticsInfo(userInfo: &userInfo, request: request, urlRequest: urlRequest)
                #endif
                
                let decoder = JSONDecoder()
                var anyCancellable = Set<AnyCancellable>()
                let config = URLSessionConfiguration.default
                if let apiVersion = request.apiVersion?.version {
                    config.httpAdditionalHeaders = [
                        "apiVersion": apiVersion
                    ]
                }
                let urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
                urlSession.dataTaskPublisher(for: urlRequest)
                    .subscribe(on: DispatchQueue.global(qos: .background))
                    .tryMap({ output in
                        do {
                            let validatingResponse = try self.tryCombineRequest(
                                urlRequest: urlRequest,
                                output: output,
                                request: request,
                                userInfo: &userInfo
                            )
                            return validatingResponse
                        } catch let err {
                            switch customRequestType {
                            case .zammad:
                                if let response = try? JSONDecoder().decode(ZammadErrorResponse.self, from: output.data) {
                                    let errMessage = response.error
                                    print("API error message", errMessage)
                                    #if !AppClip && !OrderWidget && !NotificationService
                                    userInfo.updateValue(errMessage, forKey: "error")
//                                    NonFatalError_Crashlystics().reportNonFatalCrash(
//                                        domain: "Networking-\(urlRequest.url?.absoluteString ?? "")",
//                                        domainCode: request.domainModeling.domainCode,
//                                        userInfo: userInfo
//                                    )
                                    #endif
                                    if let statusCode = (output.response as? HTTPURLResponse)?.statusCode {
                                        throw APIError.init(statusCode, with: errMessage)
                                    } else {
                                        throw APIError.init(.requestFailed, with: errMessage)
                                    }
                                }
                            default:
                                break
                            }
                            print("---------------------------------------")
                            print("---------------------------------------")
                            print("Response Error", (request.domainModeling.path+(request.path ?? "")))
                            print("---------------------------------------")
                            print("---------------------------------------")
                            #if !AppClip && !OrderWidget && !NotificationService
                            userInfo.updateValue(err.localizedDescription, forKey: "error")
//                            NonFatalError_Crashlystics().reportNonFatalCrash(
//                                domain: "Networking-\(urlRequest.url?.absoluteString ?? "")",
//                                domainCode: request.domainModeling.domainCode,
//                                userInfo: userInfo
//                            )
                            #endif
                            throw err
                        }
                    })
                    .decode(type: Response.self, decoder: decoder)
                    .tryMap({ response in
                        return response
                    })
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let err):
                            #if !AppClip && !OrderWidget && !NotificationService
                            userInfo.updateValue(err.localizedDescription, forKey: "error")
//                            NonFatalError_Crashlystics().reportNonFatalCrash(
//                                domain: "Networking-\(urlRequest.url?.absoluteString ?? "")",
//                                domainCode: request.domainModeling.domainCode,
//                                userInfo: userInfo
//                            )
                            #endif
                            if let error = err as? APIError {
                                promise(.failure(error))
                            } else {
                                promise(.failure(.init(.internalError, with: err.localizedDescription)))
                            }
                        }
                    }, receiveValue: { result in
                        promise(.success(result))
                    })
                    .store(in: &anyCancellable)
            } catch let err {
                let apiRequestError = APIError(.APIRequest, with: err.localizedDescription)
                userInfo.updateValue(apiRequestError.localizedDescription, forKey: "error")
                userInfo.updateValue("Request creation", forKey: "from")
                #if !AppClip && !OrderWidget && !NotificationService
//                NonFatalError_Crashlystics().reportNonFatalCrash(
//                    domain: "Networking-\(request.generatedPath())",
//                    domainCode: request.domainModeling.domainCode,
//                    userInfo: userInfo
//                )
                #endif
                promise(.failure(apiRequestError))
            }
        }
    }
    
    public func jsonCombineRequest(request: APIRequests) -> Future<Data, APIError> {
        return Future<Data, APIError> { promise in
            #if !AppClip && !OrderWidget && !NotificationService
            guard APIReachability.isConnectedToNetwork() else {
                let internetConnectionError = APIError(.internetConnection)
                promise(.failure(internetConnectionError))
                return
            }
            #endif
            var userInfo: [String: Any] = [
                "function": #function
            ]
            do {
                let urlRequest = try self.initRequest(APIRequest: request)
                #if !AppClip && !OrderWidget && !NotificationService
//                    NonFatalError_Crashlystics.fillCrashlyticsInfo(userInfo: &userInfo, request: request, urlRequest: urlRequest)
                #endif
                
                var anyCancellable = Set<AnyCancellable>()
                let config = URLSessionConfiguration.default
                if let apiVersion = request.apiVersion?.version {
                    config.httpAdditionalHeaders = [
                        "apiVersion": apiVersion
                    ]
                }
                let urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
                urlSession.dataTaskPublisher(for: urlRequest)
                    .subscribe(on: DispatchQueue.global(qos: .background))
                    .tryMap({ output -> Data in
                        do {
                            let validatingResponse = try self.tryCombineRequest(
                                urlRequest: urlRequest,
                                output: output,
                                request: request,
                                userInfo: &userInfo
                            )
                            return validatingResponse
                        } catch let err {
                            print("---------------------------------------")
                            print("---------------------------------------")
                            print("Response Error", (request.domainModeling.path+(request.path ?? "")))
                            print("---------------------------------------")
                            print("---------------------------------------")
                            #if !AppClip && !OrderWidget && !NotificationService
                            userInfo.updateValue(err.localizedDescription, forKey: "error")
//                            NonFatalError_Crashlystics().reportNonFatalCrash(
//                                domain: "Networking-\(urlRequest.url?.absoluteString ?? "")",
//                                domainCode: request.domainModeling.domainCode,
//                                userInfo: userInfo
//                            )
                            #endif
                            throw err
                        }
                    })
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let err):
                            #if !AppClip && !OrderWidget && !NotificationService
                            userInfo.updateValue(err.localizedDescription, forKey: "error")
//                            NonFatalError_Crashlystics().reportNonFatalCrash(
//                                domain: "Networking-\(urlRequest.url?.absoluteString ?? "")",
//                                domainCode: request.domainModeling.domainCode,
//                                userInfo: userInfo
//                            )
                            #endif
                            if let error = err as? APIError {
                                promise(.failure(error))
                            } else {
                                promise(.failure(.init(.internalError, with: err.localizedDescription)))
                            }
                        }
                    }, receiveValue: { result in
                        promise(.success(result))
                    })
                    .store(in: &anyCancellable)
            } catch let err {
                let apiRequestError = APIError(.APIRequest, with: err.localizedDescription)
                userInfo.updateValue(apiRequestError.localizedDescription, forKey: "error")
                userInfo.updateValue("Request creation", forKey: "from")
                #if !AppClip && !OrderWidget && !NotificationService
//                NonFatalError_Crashlystics().reportNonFatalCrash(
//                    domain: "Networking-\(request.generatedPath())",
//                    domainCode: request.domainModeling.domainCode,
//                    userInfo: userInfo
//                )
                #endif
                promise(.failure(apiRequestError))
            }
        }
    }
    
    private func tryCombineRequest(
        urlRequest: URLRequest,
        output: URLSession.DataTaskPublisher.Output,
        request: APIRequests,
        userInfo: inout [String: Any]
    ) throws -> Data {
        guard let response = output.response as? HTTPURLResponse,
              try !responseHasError(
                urlRequest: urlRequest,
                response,
                output.data,
                request: request,
                userInfo: &userInfo
              ) else {
            throw APIError.init(.requestFailed, with: nil)
        }
        do {
            let data = output.data
            let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
            guard JSONSerialization.isValidJSONObject(json) else {
                let string = String(data: data, encoding: .utf8)
                print(string ?? "")
                if let json = string {
                    userInfo.updateValue(json, forKey: "data")
                } else {
                    userInfo.updateValue("Couldnt parse response to string", forKey: "data")
                }
                userInfo.updateValue(APIError(.invalidData).localizedDescription, forKey: "error")
                throw APIError.init(.invalidJsonData, with: nil)
            }
            return data
        } catch let err {
            throw APIError.init(.invalidJsonData, with: err.localizedDescription)
        }
    }
    
    private func responseHasError(
        urlRequest: URLRequest,
        _ httpResponse: HTTPURLResponse,
        _ data: Data,
        request: APIRequests,
        userInfo: inout [String: Any]
    ) throws -> Bool {
        let statusCode = httpResponse.statusCode
        userInfo.updateValue(httpResponse.statusCode, forKey: "status_code")
        guard !((200..<299) ~= statusCode) else { return false }
        let apiError: APIError = .init(statusCode) { (message, error) in
            switch error {
            case .unauthorized:
                let text = "Your session has been expired, please logout and login to enjoy our services"
                message = text
            default:
                return
            }
        }
        switch apiError.error {
        case .unauthorized:
            break
        default:
            userInfo.updateValue(apiError.localizedDescription, forKey: "error")
        }
        if let data = String.init(data: data, encoding: .utf8) {
            userInfo.updateValue(data, forKey: "data")
        }
        #if !AppClip && !OrderWidget && !NotificationService
//        NonFatalError_Crashlystics().reportNonFatalCrash(
//            domain: "Networking-\(urlRequest.url?.absoluteString ?? "")",
//            domainCode: request.domainModeling.domainCode,
//            userInfo: userInfo
//        )
        #endif
        throw apiError
    }
}
