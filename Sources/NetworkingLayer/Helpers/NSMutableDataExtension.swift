//
//  NSMutableDataExtension.swift
//  NetworkingLayer
//
//  Created by Fahed Alahmad on 08/01/2025.
//

import Foundation

extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
