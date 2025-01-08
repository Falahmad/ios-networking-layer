//
//  APIOperations.swift
//  JustDeliver
//
//  Created by Fahed Al-Ahmad on 9/9/19.
//

import CoreData
import Foundation

public enum APIObservationTypes {
    case empty
    case closure
    case delegate
    case notification
}

public protocol APIOperationDelegate: AnyObject {
    func didFinish(with error: APIError, _ operationName: String)
    func didFinish<Response>(
        result: APIResult2<Response, APIError>, _ operationName: String)
    where Response: APIResponseProtocol
}

public protocol APIOperationProtocol {

    var sessionTask: URLSessionTask? { get set }
    var hasLoading: Bool { get set }
    var request: URLRequest? { get set }
    var operationName: String { get }
    var context: NSManagedObjectContext? { get }
    var observationType: APIObservationTypes { get }
}

public final class APIOperation<Response, DecodeType>: Operation, @unchecked Sendable, APIOperationProtocol where Response: APIResponseProtocol, DecodeType: Decodable {

    private let lock = NSLock()
    public var sessionTask: URLSessionTask? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _sessionTask
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _sessionTask = newValue
        }
    }
    private var _sessionTask: URLSessionTask?
    public var hasLoading: Bool
    public var request: URLRequest?
    private(set) public var observationType: APIObservationTypes
    private(set) var notificationName: Notification.Name?
    private(set) public var context: NSManagedObjectContext?
    private(set) var userInfo: [String: Any]
    private(set) var domainCode: Int
    public weak var delegate: APIOperationDelegate?
    public var observation:
        ((APIResult2<Response, APIError>, _ operationName: String) -> Void)?

    public var operationName: String {
        return self.name ?? "Default"
    }

    init(
        _ loading: Bool = true,
        request: URLRequest,
        observationType: APIObservationTypes,
        notificationName: Notification.Name? = nil,
        context: NSManagedObjectContext?,
        userInfo: [String: Any],
        domainCode: Int
    ) {
        self.hasLoading = loading
        self.request = request
        self.observationType = observationType
        self.notificationName = notificationName
        self.context = context
        self.userInfo = userInfo
        self.domainCode = domainCode
    }

    public override func cancel() {
        super.cancel()
        sessionTask?.cancel()
        sessionTask?.suspend()
        //        self.handleObservations(error: .init(.requestTimeout))
    }

    public override func main() {
        super.main()

        guard !isCancelled else {
            sessionTask?.cancel()
            sessionTask?.suspend()
            self.handleObservations(error: .init(.requestTimeout))
            return
        }
        fillCrashlyticsInfo()
        if let request = self.request {
            let config = URLSessionConfiguration.default
            if let url = request.url?.absoluteString {
                if url.contains("v3") {
                    config.httpAdditionalHeaders?.updateValue(
                        "v3", forKey: "apiVersion")
                } else if url.contains("v4") {
                    config.httpAdditionalHeaders?.updateValue(
                        "v4", forKey: "apiVersion")
                }
            }
            //            let urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            sessionTask = URLSession.shared.dataTask(
                with: request,
                completionHandler: { [weak self] (data, response, err) in
                    guard err == nil else {
                        print(
                            "------------------------------------------------------------"
                        )
                        print("Error", request.url ?? "URL")
                        print(
                            "------------------------------------------------------------"
                        )
                        print(err ?? "")
                        self?.handleObservations(error: .init())
                        return
                    }

                    guard let data = data else {
                        self?.handleObservations(error: .init(.invalidData))
                        return
                    }
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self?.handleObservations(error: .init(.requestFailed))
                        return
                    }
                    self?.handleResponse(data, httpResponse)
                })
            sessionTask?.resume()
        }
    }

    private func handleResponse(_ data: Data, _ httpResponse: HTTPURLResponse) {
        userInfo.updateValue(httpResponse.statusCode, forKey: "status_code")
        do {
            let json = try JSONSerialization.jsonObject(
                with: data, options: [.allowFragments])
            guard JSONSerialization.isValidJSONObject(json) else {
                let string = String(data: data, encoding: .utf8)
                print(string ?? "")
                if let json = string {
                    userInfo.updateValue(json, forKey: "data")
                } else {
                    userInfo.updateValue(
                        "Couldnt parse response to string", forKey: "data")
                }
                userInfo.updateValue(
                    APIError(.invalidData).localizedDescription, forKey: "error"
                )
                reportNonFatalCrash(domainCode: -1)
                self.handleObservations(error: .init(.invalidJsonData))
                return
            }
            //            print(json)
        } catch let err {
            let string = String(data: data, encoding: .utf8)
            print(string ?? "")
            if let json = string {
                userInfo.updateValue(json, forKey: "data")
            } else {
                userInfo.updateValue(
                    "Couldnt parse response to string", forKey: "data")
            }
            userInfo.updateValue(
                APIError.init(.invalidJsonData).localizedDescription,
                forKey: "error")
            reportNonFatalCrash(domainCode: -1)
            print("Incoming json is not valid", err)
            self.handleObservations(error: .init(.invalidJsonData))
            return
        }

        let decoder = JSONDecoder()
        decoder.userInfo[.context ?? CodingUserInfoKey.context!] = context
        if DecodeType.self is NSManagedObject.Type {
            guard let context = context else {
                handleObservations(
                    error: APIError.init(
                        .requestFailed, with: "Context is missing"))
                return
            }
            context.performAndWait { [unowned self] in
                do {
                    let syncEngingAPIResponse = try decoder.decode(
                        Response.self, from: data)
                    guard !responseHasError(httpResponse, syncEngingAPIResponse)
                    else {
                        printErrorResponse(for: data)
                        return
                    }
                    handleObservations(syncEngingAPIResponse)
                } catch let err {
                    print(err)
                    self.handleObservations(error: .init(.jsonParsingFailure))
                    return
                }
            }
        } else {
            do {
                let defaultAPIResponse = try decoder.decode(
                    Response.self, from: data)
                guard !responseHasError(httpResponse, defaultAPIResponse) else {
                    printErrorResponse(for: data)
                    return
                }
                handleObservations(defaultAPIResponse)
            } catch let err {
                print(err)
                self.handleObservations(error: .init(.jsonParsingFailure))
                return
            }
        }
    }

    private func responseHasError(
        _ httpResponse: HTTPURLResponse,
        _ response: Response
    ) -> Bool {
        let statucCode = httpResponse.statusCode
        guard !((200..<299) ~= statucCode) else { return false }
        let apiError: APIError = .init(statucCode) { message, error in
            if let responseMessage = response.message {
                message = responseMessage
            } else if error == .unauthorized {
                message = "Your session has been expired, please logout and login to enjoy our services"
            }
        }
        handleObservations(error: apiError)
        reportNonFatalCrash()
        return true
    }

    private func printErrorResponse(for data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            print(
                "------------------------------------------------------------")
            print(json)
            print(
                "------------------------------------------------------------")
            userInfo.updateValue(json, forKey: "data")
        } catch {
            print(APIError.init(.invalidJsonData).localizedDescription)
        }
    }

    private func reportNonFatalCrash(domainCode: Int? = nil) {
        #if !AppClip && !OrderWidget && !NotificationService
//            NonFatalError_Crashlystics().reportNonFatalCrash(
//                domain: "Networking-\(request?.url?.absoluteString ?? "")",
//                domainCode: domainCode ?? self.domainCode,
//                userInfo: userInfo
//            )
        #endif
    }

    private func handleObservations(error: APIError) {
        print("------------------------------------------------------------")
        print("Error", request?.url ?? "URL")
        print("------------------------------------------------------------")
        print("Observe error", error.error)
        print("Observe error", error.localizedDescription)
        switch observationType {
        case .closure where observation != nil:
            observation!(.failure(error), self.operationName)
        case .delegate where delegate != nil:
            delegate!.didFinish(with: error, self.operationName)
        case .notification where notificationName != nil:
            NotificationCenter.default.post(
                name: notificationName!, object: error)
        default:
            print("Observation is not assigned")
        }
    }

    private func handleObservations(_ response: Response) {
        print("Observe Success", operationName)
        switch observationType {
        case .closure where observation != nil:
            observation!(.success(response), self.operationName)
        case .delegate where delegate != nil:
            delegate!.didFinish(result: .success(response), self.operationName)
        case .notification where notificationName != nil:
            NotificationCenter.default.post(
                name: notificationName!, object: response)
        default:
            print("Observation is not assigned")
        }
    }

    private func fillCrashlyticsInfo() {
        guard let request else { return }
        #if !AppClip && !OrderWidget && !NotificationService
//            NonFatalError_Crashlystics.fillCrashlyticsInfo(
//                userInfo: &userInfo,
//                request: nil,
//                urlRequest: request
//            )
        #endif
    }
}
