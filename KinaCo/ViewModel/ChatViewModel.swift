//
//  ChatViewModel.swift
//  KinaCo
//
import SwiftUI
import Combine


class ChatViewModel: ObservableObject {
    @Published var messageText = ""
    @Published var messages: [Message] = [
        Message(text: "こんにちは！KinaCoです。何かお手伝いしましょうか？", isUser: false)
    ]
    func sendMessage(idToken: String?) async {
        
        let userQuery = messageText
        messages.append(Message(text: userQuery, isUser: true))
        messageText = ""
        messages.append(Message(text: "(...)", isUser: false))
        
        Task {
            do {
                let reply = try await KinaCoAPI.fetchReply(
                    query: userQuery,
                    idToken: idToken
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
