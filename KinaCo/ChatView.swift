//
//  Message.swift
//  KinaCo
//
//  Created by Yugo Noji on 2026/01/30.
//
import SwiftUI

struct ChatView: View {
    var authManager: AuthManager
    @State private var messageText = ""
    @State private var messages: [Message] = [
        Message(text: "こんにちは！KinaCoです。何かお手伝いしましょうか？", isUser: false)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(messages) { msg in
                            MessageRow(message: msg)
                        }
                    }
                    .padding(.vertical)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color.white,
                                Color(.systemBlue).opacity(0.08)
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // iOS 17以降の推奨される書き方
                .onChange(of: messages) {
                    _,
                    newValue in
                    withAnimation {
                        proxy.scrollTo(newValue.last?.id, anchor: .bottom)
                    }
                }
            }
            
            inputBar
        }
    }
    
    // UIパーツをプロパティに分けると読みやすい
    private var headerView: some View {
        VStack {
            Text("KinaCo AI").font(.headline).padding()
                .font(
                    .system(size: 18, weight: .bold, design: .rounded)
                ) // 💡 丸みのあるフォント
                .padding(.top, 10)
            Divider()
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("メッセージを入力...", text: $messageText)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(25)
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.isEmpty ? .gray : .blue)
            }
            .disabled(messageText.isEmpty)
        }
        .padding()
    }
    
    func sendMessage() {
        let userQuery = messageText
        messages.append(Message(text: userQuery, isUser: true))
        messageText = ""
        messages.append(Message(text: "(...)", isUser: false))
        
        Task {
            do {
                let reply = try await KinaCoAPI.fetchReply(
                    query: userQuery,
                    idToken: authManager.idToken
                )
                await MainActor.run {
                    messages.removeLast()
                    messages.append(Message(text: reply, isUser: false))
                }
            } catch {
                await MainActor.run {
                    messages.removeLast()
                    messages
                        .append(
                            Message(
                                text: "エラー: \(error.localizedDescription)",
                                isUser: false
                            )
                        )
                }
            }
        }
    }
}
