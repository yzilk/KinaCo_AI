//
//  ThreadViewModel.swift
//  KinaCo
//
import Combine
import Foundation

class ThreadViewModel: ObservableObject {
    @Published var threads: [KinaCoThread] = []
    
    private let lastFetchedKey = "threads_last_fetched"
    private let cacheKey = "threads_cache"
    
    // 1時間以上経ってたらtrue
    var shouldRefresh: Bool {
        let last = UserDefaults.standard.double(forKey: lastFetchedKey)
        return Date().timeIntervalSince1970 - last > 3600
    }
    
    init() {
        loadFromCache()
    }
    
    // キャッシュから読む
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([KinaCoThread].self, from: data) {
            self.threads = decoded
        }
    }
    
    // キャッシュに保存
    private func saveToCache(_ threads: [KinaCoThread]) {
        if let encoded = try? JSONEncoder().encode(threads) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastFetchedKey)
        }
    }
    
    func loadThreads(authManager: AuthManager) async {
        print("🧸 loadThreads呼ばれた")
        guard let token = authManager.idToken else {
            print("🧸 tokenがnil")
            return
        }
        do {
            let result = try await KinaCoThreadAPI.fetchThreads(idToken: token)
            print("🧸 取得件数: \(result.count)")
            await MainActor.run { threads = result }
        } catch {
            print("🧸 スレッド取得エラー: \(error)")
        }
    }
    
    func saveThread(_ thread: KinaCoThread, authManager: AuthManager) async {
        guard let token = authManager.idToken else { return }
        do {
            try await KinaCoThreadAPI.saveThread(thread, idToken: token)
            await loadThreads(authManager: authManager)
        } catch {
            print("スレッド保存エラー: \(error)")
        }
    }
}

