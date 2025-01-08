//
//  API+DomainModeling.swift
//  justclean
//
//  Created by Fahed Al-Ahmad on 27/01/2021.
//  Copyright © 2021 Justclean. All rights reserved.
//

import Foundation
import SwiftUI

public enum DomainModeling: Int {
    case empty = 1
    
    
    var path: String {
        switch self {
        case .empty: return ""
        
        }
    }
    var domainCode: Int {
        rawValue
    }
}
