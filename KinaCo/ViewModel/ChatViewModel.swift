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
        didSet { saveToDisk() }
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
            self.messages = [Message(text: "こんにちは！キナコです🐾 今日の体調はどうですか？", isUser: false)]
        }
    }

    // MARK: - 通常チャット送信
    @MainActor
    func sendMessage(authManager: AuthManager) async {
        guard let token = authManager.idToken else {
            messages.append(Message(text: "ログインが必要です", isUser: false))
            return
        }
        let userQuery = messageText
        guard !userQuery.isEmpty else { return }

        messages.append(Message(text: userQuery, isUser: true))
        messageText = ""
        messages.append(Message(text: "(...)", isUser: false))

        do {
            let reply = try await KinaCoAPI.fetchReply(query: userQuery, idToken: token)
            messages.removeLast()
            messages.append(Message(text: reply, isUser: false))
        } catch {
            messages.removeLast()
            messages.append(Message(text: "エラー: \(error.localizedDescription)", isUser: false))
        }
    }

    // MARK: - ヘルスレポートをチャットに流し込む（キナコへの相談）
    @MainActor
    func sendHealthReport(report: HealthReport, authManager: AuthManager) async {
        guard let token = authManager.idToken else { return }

        let summary = """
        【今日のバイタルレポート】
        歩数: \(Int(report.steps))歩
        睡眠: \(String(format: "%.1f", report.sleepHours))時間
        心拍数: \(Int(report.heartRate))bpm
        HRV: \(Int(report.hrv))ms
        安静時心拍: \(Int(report.restingHR))bpm
        """

        messages.append(Message(text: summary, isUser: true))
        messages.append(Message(text: "(...)", isUser: false))

        do {
            let reply = try await KinaCoAPI.fetchReply(query: summary, idToken: token)
            messages.removeLast()
            messages.append(Message(text: reply, isUser: false))
        } catch {
            messages.removeLast()
            messages.append(Message(text: "エラー: \(error.localizedDescription)", isUser: false))
        }
    }
}

// MARK: - Live Activity
extension ChatViewModel {
    func startKinaco() {
        if #available(iOS 16.2, *) {
            let attributes = KinacoAttributes(title: "キナコ")
            let initialState = KinacoAttributes.ContentState(message: "今日のバイタルを確認中🐾")
            let content = ActivityContent(state: initialState, staleDate: nil)
            do {
                let activity = try Activity.request(attributes: attributes, content: content)
                print("Live Activity開始: \(activity.id)")
            } catch {
                print("Live Activityエラー: \(error.localizedDescription)")
            }
        }
    }
}
