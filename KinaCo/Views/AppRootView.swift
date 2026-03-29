//
//  AppRootView.swift
//  KinaCo
//

import SwiftUI

struct AppRootView: View {
    @Environment(AuthManager.self) var authManager

    var body: some View {
        if authManager.isSignedIn {
            TabView {
                ThreadView()
                    .tabItem {
                        Label("レポート", systemImage: "heart.text.square.fill")
                    }
                ChatView()
                    .tabItem {
                        Label("相談", systemImage: "bubble.left.fill")
                    }
            }
            .tint(.orange)
        } else {
            LoginView()
        }
    }
}
