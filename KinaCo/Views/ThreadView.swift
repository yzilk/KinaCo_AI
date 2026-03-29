//
//  ThreadView.swift (HealthView)
//  KinaCo
//

import SwiftUI

struct ThreadView: View {
    @Environment(AuthManager.self) var authManager
    @StateObject private var viewModel = ThreadViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let report = viewModel.todayReport {
                        todayCard(report: report)
                        if let advice = report.aiAdvice {
                            adviceCard(advice: advice)
                        }
                        if !viewModel.recentReports.isEmpty {
                            recentSection
                        }
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("きなこレポート 🐾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.fetchAndAnalyze(authManager: authManager) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.fetchAndAnalyze(authManager: authManager)
                await viewModel.loadRecentReports(authManager: authManager)
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - 今日のバイタルカード
    private func todayCard(report: HealthReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今日のバイタル")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(icon: "figure.walk", label: "歩数", value: String(format: "%.0f", report.steps), unit: "歩", color: .green)
                MetricTile(icon: "moon.zzz.fill", label: "睡眠", value: String(format: "%.1f", report.sleepHours), unit: "時間", color: .indigo)
                MetricTile(icon: "heart.fill", label: "心拍数", value: String(format: "%.0f", report.heartRate), unit: "bpm", color: .red)
                MetricTile(icon: "waveform.path.ecg", label: "HRV", value: String(format: "%.0f", report.hrv), unit: "ms", color: .orange)
                MetricTile(icon: "heart.circle", label: "安静時心拍", value: String(format: "%.0f", report.restingHR), unit: "bpm", color: .pink)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - キナコのアドバイスカード
    private func adviceCard(advice: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🐾 キナコからのアドバイス")
                    .font(.headline)
                Spacer()
            }
            Text(advice)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color.orange.opacity(0.12))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }

    // MARK: - 過去レポート一覧
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("過去のレポート")
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(viewModel.recentReports.prefix(5)) { report in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.date)
                            .font(.subheadline.bold())
                        Text("歩数: \(Int(report.steps))歩 / 睡眠: \(String(format: "%.1f", report.sleepHours))h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                Divider()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - ローディング
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("バイタルを解析中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - 空状態
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("今日のレポートはまだありません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("HealthKitの権限を許可して\nキナコに分析してもらいましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("データを取得する") {
                Task { await viewModel.fetchAndAnalyze(authManager: authManager) }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - MetricTile
struct MetricTile: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
