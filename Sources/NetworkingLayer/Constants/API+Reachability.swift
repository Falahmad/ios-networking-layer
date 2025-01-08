//
//  Reachability.swift
//  JustDeliver
//
//  Created by Fahed Al-Ahmad on 9/9/19.
//

import SystemConfiguration
import Reachability

protocol ReachabilityActionDelegate {
    func reachabilityChanged(_ isReachable: Bool)
}

// MARK: - ReachabilityActionDelegate
protocol ReachabilityObserverDelegate: AnyObject, ReachabilityActionDelegate {
    func addReachabilityObserver() throws
    
    func removeReachabilityObserver()
}

/// Declaring default implementation of adding/removing observer
extension ReachabilityObserverDelegate {
    /** Subscribe on reachability changing */
    func addReachabilityObserver() throws -> Reachability {
        let reachability = try Reachability()
        reachability.whenReachable = { [weak self] reachability in
            self?.reachabilityChanged(true)
        }
        reachability.whenUnreachable = { [weak self] reachability in
            self?.reachabilityChanged(false)
        }
        try reachability.startNotifier()
        return reachability
    }
    
    /** Unsubscribe */
    func removeReachabilityObserver(reachability: Reachability) {
        reachability.stopNotifier()
    }
    
}

public class APIReachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
       /// Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        return (ret && ((try? Reachability())?.connection != Optional.none))
    }
}
