//
//  API+Result+Default.swift
//  JustDeliver
//
//  Created by Fahed Al-Ahmad on 1/26/20.
//

import Foundation

public struct APIResponse<DecodeType: Decodable>: APIResponseProtocol, Sendable where DecodeType: Sendable {
    
    enum CodingKeys: String, CodingKey {
        case code, data, isError, message, exception, pageInfo
    }
    
    public var code: Int
    public var isError: Bool?
    public var message: String?
    private var exception: String?
    public var pageInfo: PageInfo?
    public var data: DecodeType?
    public var additionalData: [String: AdditionalDataValue]?
    
    init(isSuccess: Bool, model: DecodeType? = nil) {
        self.code = isSuccess ? 200 : 500
        self.isError = !isSuccess
        self.pageInfo = nil
        self.data = model
        self.additionalData = nil
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        code = try container.decode(Int.self, forKey: .code)
        isError = try? container.decode(Bool.self, forKey: .isError)
        if let message = try? container.decode(String.self, forKey: .message) {
            self.message = message
            self.exception = nil
        } else if let messages = try? container.decode([String].self, forKey: .message) {
            self.message = messages.first
            self.exception = nil
        } else if let exception = try? container.decode(String.self, forKey: .exception) {
            self.message = exception
            self.exception = exception
        } else {
            self.message = nil
            self.exception = nil
        }
        
        if let pageInfo = try? container.decodeIfPresent(PageInfo.self, forKey: .pageInfo) {
            self.pageInfo = pageInfo
        } else {
            self.pageInfo = nil
        }
        data = try? container.decodeIfPresent(DecodeType.self, forKey: .data)
        additionalData = nil
    }
}
