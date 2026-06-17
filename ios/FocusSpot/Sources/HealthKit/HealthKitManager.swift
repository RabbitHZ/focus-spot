import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()

    private let readTypes: Set<HKObjectType> = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
    ]

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchSnapshot() async throws -> HealthSnapshot {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        async let sleep = fetchSleep(from: yesterday, to: now)
        async let hr = fetchRestingHR()
        async let avgHR = fetchAvgHR(from: yesterday, to: now)
        async let steps = fetchSteps(from: yesterday, to: now)
        async let spo2 = fetchSPO2()
        async let rr = fetchRespiratoryRate()

        let (sleepData, heartRate, avgHeartRate, stepCount, oxygenSat, respiratoryRate) =
            try await (sleep, hr, avgHR, steps, spo2, rr)

        return HealthSnapshot(
            sleepDurationHours: sleepData.total,
            deepSleepHours: sleepData.deep,
            remSleepHours: sleepData.rem,
            lightSleepHours: sleepData.light,
            restingHeartRate: heartRate,
            avgHeartRate: avgHeartRate,
            respiratoryRate: respiratoryRate,
            spo2: oxygenSat,
            stepCount: stepCount,
            recordedAt: now
        )
    }

    // MARK: - Sleep

    private func fetchSleep(from: Date, to: Date) async throws -> (total: Double?, deep: Double?, rem: Double?, light: Double?) {
        let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var deep = 0.0, rem = 0.0, light = 0.0
                for sample in (samples as? [HKCategorySample]) ?? [] {
                    let hours = sample.endDate.timeIntervalSince(sample.startDate) / 3600
                    switch HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                    case .asleepDeep: deep += hours
                    case .asleepREM: rem += hours
                    case .asleepUnspecified, .asleepCore: light += hours
                    default: break
                    }
                }
                let total = deep + rem + light
                continuation.resume(returning: (
                    total: total > 0 ? total : nil,
                    deep: deep > 0 ? deep : nil,
                    rem: rem > 0 ? rem : nil,
                    light: light > 0 ? light : nil
                ))
            }
            store.execute(query)
        }
    }

    // MARK: - Heart Rate

    private func fetchRestingHR() async throws -> Double? {
        let type = HKQuantityType(.restingHeartRate)
        return try await fetchLatestQuantity(type: type, unit: .count().unitDivided(by: .minute()))
    }

    private func fetchAvgHR(from: Date, to: Date) async throws -> Double? {
        let type = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = stats?.averageQuantity()?.doubleValue(for: .count().unitDivided(by: .minute()))
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Steps

    private func fetchSteps(from: Date, to: Date) async throws -> Int? {
        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = stats?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: value.map { Int($0) })
            }
            store.execute(query)
        }
    }

    // MARK: - SpO2

    private func fetchSPO2() async throws -> Double? {
        let type = HKQuantityType(.oxygenSaturation)
        return try await fetchLatestQuantity(type: type, unit: .percent())
    }

    // MARK: - Respiratory Rate

    private func fetchRespiratoryRate() async throws -> Double? {
        let type = HKQuantityType(.respiratoryRate)
        return try await fetchLatestQuantity(type: type, unit: .count().unitDivided(by: .minute()))
    }

    // MARK: - Helpers

    private func fetchLatestQuantity(type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -7, to: Date()), end: Date())

        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "이 기기에서는 HealthKit을 사용할 수 없습니다."
        }
    }
}
