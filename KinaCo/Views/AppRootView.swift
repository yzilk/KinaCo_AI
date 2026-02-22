//
//  AppRootView.swift
//  KinaCo
//

import SwiftUI

struct AppRootView: View {
    @Environment(AuthManager.self) var authManager
    
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("チャット", systemImage: "bubble.left.fill")
                }
            
            ThreadView()
                .tabItem {
                    Label("きろく", systemImage: "heart.text.square.fill")
                }
        }
    }
}


