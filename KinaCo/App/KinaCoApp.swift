//
//  KinaCoApp.swift
//  KinaCo
//
import SwiftUI

@main
struct KinaCoApp: App {
    @State private var authManager = AuthManager()
    var body: some Scene {
        WindowGroup {
            ChatView()
                .environment(authManager)
        }
    }
}

