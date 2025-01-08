//
//  PushIDGenerator.swift
//  NetworkingLayer
//
//  Created by Fahed Alahmad on 08/01/2025.
//

import Foundation

final public class PushIDGenerator {
    init() { }
    
    private let PUSH_CHARS = Array("-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz")
    private var lastPushTime: UInt64 = 0
    private var lastRandChars = Array<Int>(repeating: 0, count: 12)
    
    func generate() -> String {
        var now = UInt64(NSDate().timeIntervalSince1970 * 1000)
        let duplicateTime = (now == lastPushTime)
        lastPushTime = now

        var timeStampChars = Array<Character>(repeating: PUSH_CHARS.first!, count: 8)
        for i in stride(from: 7, through: 0, by: -1) {
            timeStampChars[i] = PUSH_CHARS[Int(now % 64)]
            now >>= 6
        }
        
        assert(now == 0, "We should have converted the entire timestamp.")
        
        var id = String(timeStampChars)
        
        if !duplicateTime {
            for i in 0..<12 {
                lastRandChars[i] = Int(floor(Double.random(in: 0..<1) * 64))
            }
        }
        else {
            var i = 11
            while i >= 0 && lastRandChars[i] == 63 {
                lastRandChars[i] = 0
                i -= 1
            }
            lastRandChars[i] += 1
        }
        
        for i in 0..<12 {
            id.append(PUSH_CHARS[lastRandChars[i]])
        }
        
        assert(id.count == 20, "Length should be 20.")
        
        return id
    }
}
