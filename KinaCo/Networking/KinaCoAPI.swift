//
//  KinaCoAPI.swift
//  KinaCo
//

import Foundation

struct KinaCoAPI {
    private static var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "KINACOAPI_URL") as? String ?? ""
    }
    
    static func fetchReply(query: String, idToken: String?) async throws -> String {
        guard let url = URL(string: baseURL + "/chat") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = idToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization
            .data(withJSONObject: ["message": query])
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let debugString = String(data: data, encoding: .utf8) {
            print("📄 Lambdaからの生の声: \(debugString)")
        }
        return json?["reply"] as? String ?? "返信が空っぽだよ"
    }
}
