//
//  API+Client.swift
//
//  Created by Fahed Al-Ahmad on 9/12/19.
//

import Foundation
import CoreData
import UIKit
import Combine

public protocol APIClient {
//    func requestJSONResponse<Response, DecodeType>(
//        isCancelable: Bool,
//        loading: Bool,
//        request: APIRequests,
//        _ response: Response.Type,
//        _ decodeType: DecodeType.Type,
//        observationType: APIObservationTypes,
//        notificationName: Notification.Name?,
//        qos: DispatchQoS.QoSClass,
//        context: NSManagedObjectContext?,
//        completion: ((APIResult2<Response, APIError>) -> Void)?) ->(APIOperation<Response, DecodeType>?, APIError?)? where Response: APIResponseProtocol, DecodeType: Decodable
//    func loadImageUsingCacheWithUrlString(_ imagePath: String, completion: @escaping (UIImage?, APIError?) -> Void)
}

extension APIRoute: APIClient {
    
    public func cancelOpertaion(operationName: String) {
        DispatchQueue.global().async {[weak self] in
            for operation in self?.operations ?? [] {
                guard operation.name == operationName else { continue }
                operation.cancel()
            }
        }
    }
    
}
