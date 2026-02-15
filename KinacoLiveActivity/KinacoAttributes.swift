//
//  KinacoAttributes.swift
//  KinaCo
//
import ActivityKit

struct KinacoAttributes: ActivityAttributes {
    
    public struct ContentState: Codable, Hashable {
        var message: String
    }
    
    var title: String
}


