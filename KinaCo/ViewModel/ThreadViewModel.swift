//
//  ThreadViewModel.swift (HealthViewModel)
//  KinaCo
//
import Foundation
import Combine

// MARK: - HealthReport Model
struct HealthReport: Codable, Identifiable {
    var id: String { date }
    var date: String          // "2026-03-28"
    var steps: Double
    var sleepHours: Double
    var heartRate: Double
    var hrv: Double
    var restingHR: Double
    var aiAdvice: String?     // キナコの診断コメント
    var savedAt: String
}

// MARK: - HealthViewModel
@MainActor
class ThreadViewModel: ObservableObject {
    @Published var todayReport: HealthReport? = nil
    @Published var recentReports: [HealthReport] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let healthKit = HealthKitManager()

    // HealthKitからデータ取得 → Lambdaに送ってAI診断を受け取る
    func fetchAndAnalyze(authManager: AuthManager) async {
        guard let token = authManager.idToken else {
            errorMessage = "ログインが必要です"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1. HealthKit権限リクエスト
            try await healthKit.requestAuthorization()

            // 2. 今日のバイタル取得
            let data = try await healthKit.fetchTodayHealthData()

            // 3. Lambdaに送ってAI診断
            let advice = try await KinaCoAPI.fetchHealthAdvice(healthData: data, idToken: token)

            // 4. レポートを組み立て
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let today = formatter.string(from: Date())

            todayReport = HealthReport(
                date: today,
                steps: data["steps"] as? Double ?? 0,
                sleepHours: data["sleep_hours"] as? Double ?? 0,
                heartRate: data["heart_rate"] as? Double ?? 0,
                hrv: data["hrv"] as? Double ?? 0,
                restingHR: data["resting_hr"] as? Double ?? 0,
                aiAdvice: advice,
                savedAt: data["timestamp"] as? String ?? ""
            )

            // 5. DDBに保存
            try await KinaCoAPI.saveHealthReport(report: todayReport!, idToken: token)

        } catch {
            errorMessage = "データ取得エラー: \(error.localizedDescription)"
        }
    }

    // 過去レポートをDDBから取得
    func loadRecentReports(authManager: AuthManager) async {
        guard let token = authManager.idToken else { return }
        do {
            recentReports = try await KinaCoAPI.fetchHealthReports(idToken: token)
        } catch {
            print("過去レポート取得エラー: \(error)")
        }
    }
}
