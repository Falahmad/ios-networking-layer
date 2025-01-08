//
//  API+DomainModeling.swift
//  justclean
//
//  Created by Fahed Al-Ahmad on 27/01/2021.
//  Copyright © 2021 Justclean. All rights reserved.
//

import Foundation
import SwiftUI

public struct DomainModeling {
    let domainCode: Int
    let path: String
    
    public init(domainCode: Int, path: String) {
        self.domainCode = domainCode
        self.path = path
    }
}
