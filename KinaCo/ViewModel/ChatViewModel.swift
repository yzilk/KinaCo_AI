//
//  ChatViewModel.swift
//  KinaCo
//
import SwiftUI
import Combine
import ActivityKit

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
extension ChatViewModel {
    func startKinaco() {
        // 👇 これを追加して、全体を囲む
        if #available(iOS 16.2, *) {
            print("🛠 startKinacoが呼ばれました")
            
            let attributes = KinacoAttributes(title: "集中タイム")
            let initialState = KinacoAttributes.ContentState(message: "30分だけ集中しません？")
            let content = ActivityContent(state: initialState, staleDate: nil)
            
            do {
                let activity = try Activity.request(attributes: attributes, content: content)
                print("✅ 成功！ID: \(activity.id)")
            } catch {
                print("❌ エラー: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ このiOSバージョンではLive Activityは使えません")
        }
    }
}
