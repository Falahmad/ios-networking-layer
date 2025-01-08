//
//  DataExtension.swift
//  NetworkingLayer
//
//  Created by Fahed Alahmad on 08/01/2025.
//

import Foundation

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
    
    public func getMimeType() -> String? {
        let bytes = [UInt8](self.prefix(1))
        switch bytes {
        case [0xFF]: return "image/jpeg"  // JPEG files start with 0xFF
        case [0x89]: return "image/png"   // PNG files start with 0x89
        default: return nil               // Unsupported format
        }
    }
    
    public func getMimeTypeExtension() -> String? {
        switch self .getMimeType() {
        case "image/jpeg": return "jpeg"
        case "image/png": return "png"
        default: return nil
        }
    }
}
