//
//  ZammadErrorResponse.swift
//  justclean
//
//  Created by Fahed Al-Ahmad on 17/12/2024.
//  Copyright © 2024 Justclean. All rights reserved.
//


struct ZammadErrorResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case error
    }
    
    let error: String
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.error = try container.decode(String.self, forKey: .error)
    }
}
