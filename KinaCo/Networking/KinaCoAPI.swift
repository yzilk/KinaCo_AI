//
//  KinaCoAPI.swift
//  KinaCo
//

import Foundation

struct KinaCoAPI {
    private static var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "KINACOAPI_URL") as? String ?? ""
    }

    // MARK: - 通常チャット
    static func fetchReply(query: String, idToken: String?) async throws -> String {
        guard let url = URL(string: baseURL + "/chat") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = idToken { request.setValue(token, forHTTPHeaderField: "Authorization") }
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["message": query])

        let (data, _) = try await URLSession.shared.data(for: request)
        if let debug = String(data: data, encoding: .utf8) { print("📄 chat reply: \(debug)") }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["reply"] as? String ?? "返信が空っぽだよ"
    }

    // MARK: - ヘルスデータをLambdaに送ってAI診断を受け取る
    // Lambda側: POST /health/analyze → DDBにREPORT#<date>で保存 → adviceを返す
    static func fetchHealthAdvice(healthData: [String: Any], idToken: String) async throws -> String {
        guard let url = URL(string: baseURL + "/health/analyze") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(idToken, forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: healthData)

        let (data, _) = try await URLSession.shared.data(for: request)
        if let debug = String(data: data, encoding: .utf8) { print("📄 health advice: \(debug)") }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["advice"] as? String ?? "今日も元気そうだよ🐾"
    }

    // MARK: - 日次レポートをDDBに保存
    // SK: REPORT#<date>
    static func saveHealthReport(report: HealthReport, idToken: String) async throws {
        guard let url = URL(string: baseURL + "/health/report") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(idToken, forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(report)
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - 過去レポートをDDBから取得
    // SK begins_with "REPORT#"
    static func fetchHealthReports(idToken: String) async throws -> [HealthReport] {
        guard let url = URL(string: baseURL + "/health/reports") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(idToken, forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        return (try? JSONDecoder().decode([HealthReport].self, from: data)) ?? []
    }
}
