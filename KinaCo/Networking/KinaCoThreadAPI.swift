//
//  KinaCoThreadAPI.swift
//  KinaCo
//

import Foundation

struct KinaCoThreadAPI {
    
    private static var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "KINACOAPI_URL") as? String ?? ""
    }
    
    // スレッド取得
    static func fetchThreads(idToken: String) async throws -> [KinaCoThread] {
        guard let url = URL(string: baseURL + "/threads") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(idToken, forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([KinaCoThread].self, from: data)
    }
    
    // スレッド保存（ユーザー編集）
    static func saveThread(_ thread: KinaCoThread, idToken: String) async throws {
        guard let url = URL(string: baseURL + "/threads") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(idToken, forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(thread)
        
        _ = try await URLSession.shared.data(for: request)
        
    }
}
