//
//  StringExtension.swift
//  NetworkingLayer
//
//  Created by Fahed Alahmad on 08/01/2025.
//

import Foundation

public extension String {
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}
