//
//  Config+APIRequest.swift
//  JustDeliver
//
//  Created by Fahed Al-Ahmad on 9/12/19.
//

import Foundation

protocol APIConfigurationProtocol {
    var appURL: String? { get set }
    var APIURL: String? { get set }
    var APINestURL: String? { get set }
    var APIKey: String? { get set }
    var APIApplicationVersion: String? { get set }
    
    var applicationVersionWithBuild: String? { get set }
    var applicationVersion: String? { get set }
}
