//
//  Message.swift
//  KinaCo
//
//  Created by Yugo Noji on 2026/01/30.
//
import Foundation

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}
