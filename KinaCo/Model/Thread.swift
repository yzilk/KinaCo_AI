//
//  Thread.swift
//  KinaCo
//

// Model/Thread.swift

import Foundation

struct ThreadItem: Codable, Identifiable {
    var id: String { content } // ← これに変更
//    var id = UUID()
    var content: String
    var confirmed: Bool
    var createdAt: String
}

struct KinaCoThread: Codable, Identifiable {
    var id: String { threadId }
    var threadId: String
    var category: String
    var items: [ThreadItem]
    var updatedAt: String
}
