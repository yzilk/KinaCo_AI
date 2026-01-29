//
//  KinaCoApp.swift
//  KinaCo
//
//  Created by Yugo Noji on 2026/01/18.
//

import SwiftUI

@main
struct KinaCoApp: App {
    @State private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ChatView(authManager: authManager)
//            if authManager.isSignedIn {
//                // ログイン済み：メインのチャット画面へ
//                ChatView(authManager: authManager)
//            } else {
//                // 未ログイン：ログイン画面へ
//                LoginView(authManager: authManager)
//            }
           
        }
    }
}

