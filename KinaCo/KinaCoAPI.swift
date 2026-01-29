//
//  KinaCoAPI.swift
//  KinaCo
//
//  Created by Yugo Noji on 2026/01/30.
//

import Foundation

struct KinaCoAPI {
//    static func fetchReply(query: String, idToken: String?) async throws -> String {
//        let urlString = Bundle.main.object(
//            forInfoDictionaryKey: "LAMBDA_URL"
//        ) as? String ?? ""
//        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        if let token = idToken {
//            request.setValue(token, forHTTPHeaderField: "Authorization")
//        }
//        
//        request.httpBody = try? JSONSerialization
//            .data(withJSONObject: ["message": query])
//        
//        let (data, _) = try await URLSession.shared.data(for: request)
//        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
//        return json?["reply"] as? String ?? "返信が空っぽだよ"
//    }
    // KinaCoAPI.swift 内で一時的に
    static func fetchReply(query: String, idToken: String?) async throws -> String {
        // 通信をコメントアウトして、ダミーを返す
        try? await Task.sleep(nanoseconds: 1 * 1000_000_000) // 1秒待つフリ
        return "デザイン確認用のテスト返信だよ！🐥"
    }
}
