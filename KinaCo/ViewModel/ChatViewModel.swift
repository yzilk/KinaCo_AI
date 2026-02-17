//
//  ChatViewModel.swift
//  KinaCo
//
import SwiftUI
import Combine
import ActivityKit

class ChatViewModel: ObservableObject {
    @Published var messageText = ""
    @Published var messages: [Message] = [] {
        didSet {
            saveToDisk()
        }
    }
    private let storageKey = "kinaco_chat_history"
    
    init() {
        loadFromDisk()
    }
    
    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Message].self, from: data) {
            self.messages = decoded
        } else {
            self.messages = [Message(text: "初めまして！KinaCoです。何かお手伝いしましょうか？", isUser: false)]
        }
    }
    @MainActor
    func sendMessage(authManager: AuthManager) async {
        // 1. トークンを authManager から取り出す
        guard let token = authManager.idToken else {
            print("🚨 トークンがないよ！ログインしてね。")
            return
        }
        
        // 入力した文字を一時保存して、入力欄を空にする
        let userQuery = messageText
        if userQuery.isEmpty { return }
        
        // 画面にユーザーのメッセージと「(...)」を表示
        messages.append(Message(text: userQuery, isUser: true))
        messageText = ""
        messages.append(Message(text: "(...)", isUser: false))
        
        // 2. APIを叩く（ここでは fetchReply を使う）
        do {
            // ここでさっき取り出した 'token' を使う
            let reply = try await KinaCoAPI.fetchReply(
                query: userQuery,
                idToken: token
            )
            
            // 返ってきたら「(...)」を消して、キナコの返信を表示
            messages.removeLast()
            messages.append(Message(text: reply, isUser: false))
            
        } catch {
            print("❌ エラー: \(error.localizedDescription)")
            messages.removeLast()
            messages.append(Message(text: "エラー: \(error.localizedDescription)", isUser: false))
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
