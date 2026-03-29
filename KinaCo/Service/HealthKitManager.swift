import Foundation
import HealthKit

@Observable
class HealthKitManager {
    let healthStore = HKHealthStore()
    
    // 5つの解析対象
    let typesToRead: Set<HKObjectType> = [
        .categoryType(forIdentifier: .sleepAnalysis)!,
        .quantityType(forIdentifier: .stepCount)!,
        .quantityType(forIdentifier: .heartRate)!,
        .quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        .quantityType(forIdentifier: .restingHeartRate)!
    ]
    
    // 権限リクエスト
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthError.notAvailable
        }
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    // 今日の5大データを辞書にまとめる
    func fetchTodayHealthData() async throws -> [String: Any] {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        // 5つのデータを並列で取得
        async let steps = fetchSum(for: .stepCount, predicate: predicate)
        async let sleep = fetchSleep(predicate: predicate)
        async let hr = fetchLatest(for: .heartRate)
        async let hrv = fetchLatest(for: .heartRateVariabilitySDNN)
        async let rhr = fetchLatest(for: .restingHeartRate)
        
        return [
            "steps": await steps,
            "sleep_hours": await sleep,
            "heart_rate": await hr,
            "hrv": await hrv,
            "resting_hr": await rhr,
            "timestamp": ISO8601DateFormatter().string(from: now)
        ]
    }
    
    // --- ヘルパー関数群 ---
    private func fetchSum(for id: HKQuantityTypeIdentifier, predicate: NSPredicate) async -> Double {
        let type = HKQuantityType.quantityType(forIdentifier: id)!
        let samplePredicate = HKSamplePredicate.quantitySample(type: type, predicate: predicate)
        let descriptor = HKStatisticsQueryDescriptor(predicate: samplePredicate, options: .cumulativeSum)
        do {
            let result = try await descriptor.result(for: healthStore)
            // 単位を動的に判定
            let unit: HKUnit = (id == .stepCount) ? .count() : HKUnit(from: "count/min")
            return result?.sumQuantity()?.doubleValue(for: unit) ?? 0
        } catch {
            return 0
        }
    }
    
    private func fetchSleep(predicate: NSPredicate) async -> Double {
        let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let samplePredicate = HKSamplePredicate.categorySample(type: type, predicate: predicate)
        let descriptor = HKSampleQueryDescriptor(predicates: [samplePredicate], sortDescriptors: [])
        do {
            let samples = try await descriptor.result(for: healthStore)
            let totalSeconds = samples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            return totalSeconds / 3600
        } catch {
            return 0
        }
    }
    
    private func fetchLatest(for id: HKQuantityTypeIdentifier) async -> Double {
        let type = HKQuantityType.quantityType(forIdentifier: id)!
        let samplePredicate = HKSamplePredicate.quantitySample(type: type)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )
        do {
            let results = try await descriptor.result(for: healthStore)
            guard let latest = results.first else { return 0 }
            
            let unit: HKUnit
            if id == .heartRateVariabilitySDNN {
                unit = .secondUnit(with: .milli)
            } else {
                unit = HKUnit(from: "count/min")
            }
            return latest.quantity.doubleValue(for: unit)
        } catch {
            return 0
        }
    }
}

enum HealthError: Error {
    case notAvailable
}
