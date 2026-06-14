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
        async let steps = fetchSteps(from: yesterday, to: now)
        async let spo2 = fetchSPO2()
        async let rr = fetchRespiratoryRate()

        let (sleepData, heartRate, stepCount, oxygenSat, respiratoryRate) =
            try await (sleep, hr, steps, spo2, rr)

        return HealthSnapshot(
            sleepDurationHours: sleepData.total,
            deepSleepHours: sleepData.deep,
            remSleepHours: sleepData.rem,
            lightSleepHours: sleepData.light,
            restingHeartRate: heartRate,
            spo2: oxygenSat,
            respiratoryRate: respiratoryRate,
            stepCount: stepCount,
            recordedAt: now
        )
    }

    // MARK: - Private fetch helpers (stub implementations)

    private func fetchSleep(from: Date, to: Date) async throws -> (total: Double?, deep: Double?, rem: Double?, light: Double?) {
        // TODO: HKCategoryTypeIdentifier.sleepAnalysis 쿼리 구현
        return (nil, nil, nil, nil)
    }

    private func fetchRestingHR() async throws -> Double? {
        // TODO: HKQuantityTypeIdentifier.restingHeartRate 쿼리 구현
        return nil
    }

    private func fetchSteps(from: Date, to: Date) async throws -> Int? {
        // TODO: HKQuantityTypeIdentifier.stepCount 쿼리 구현
        return nil
    }

    private func fetchSPO2() async throws -> Double? {
        // TODO: HKQuantityTypeIdentifier.oxygenSaturation 쿼리 구현
        return nil
    }

    private func fetchRespiratoryRate() async throws -> Double? {
        // TODO: HKQuantityTypeIdentifier.respiratoryRate 쿼리 구현
        return nil
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
