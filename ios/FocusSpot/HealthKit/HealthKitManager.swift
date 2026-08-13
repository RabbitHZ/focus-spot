import Foundation
import HealthKit

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

    // 오늘 심박 데이터가 있는지, 최근 수면이 48시간 이내인지 체크
    func checkDataFreshness() async -> (hasHeartRate: Bool, hasSleep: Bool) {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let now = Date()

        let hrType = HKQuantityType(.heartRate)
        let hrPredicate = HKQuery.predicateForSamples(withStart: todayStart, end: now, options: .strictStartDate)
        let hasHR: Bool = await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: hrType, predicate: hrPredicate, limit: 1, sortDescriptors: nil) { _, samples, _ in
                cont.resume(returning: !(samples ?? []).isEmpty)
            }
            store.execute(q)
        }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let sleepStart = Calendar.current.date(byAdding: .hour, value: -48, to: now)!
        let sleepPredicate = HKQuery.predicateForSamples(withStart: sleepStart, end: now, options: .strictStartDate)
        let hasSleep: Bool = await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: sleepType, predicate: sleepPredicate, limit: 1, sortDescriptors: nil) { _, samples, _ in
                let asleep = (samples as? [HKCategorySample])?.first {
                    let v = HKCategoryValueSleepAnalysis(rawValue: $0.value)
                    return v == .asleepDeep || v == .asleepREM || v == .asleepCore || v == .asleepUnspecified
                }
                cont.resume(returning: asleep != nil)
            }
            store.execute(q)
        }

        print("[HealthKit] freshness check: hasHR=\(hasHR) hasSleep=\(hasSleep)")
        return (hasHR, hasSleep)
    }

    func authorizationDebug() -> String {
        readTypes.map { type in
            let s = store.authorizationStatus(for: type)
            let label = s == .sharingAuthorized ? "✓" : s == .sharingDenied ? "✗" : "?"
            return "\(label) \(type.identifier.split(separator: ".").last ?? "")"
        }.sorted().joined(separator: "\n")
    }

    func fetchSnapshot() async -> HealthSnapshot {
        let now = Date()
        let sleepStart = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        print("[HealthKit] fetchSnapshot start")

        let sleepData: (total: Double?, deep: Double?, rem: Double?, light: Double?)
        let heartRate: Double?
        let avgHeartRate: Double?
        let stepCount: Int?
        let oxygenSat: Double?
        let respiratoryRate: Double?

        do { sleepData = try await fetchSleep(from: sleepStart, to: now) }
        catch { print("[HealthKit] fetchSleep ERROR: \(error)"); sleepData = (nil, nil, nil, nil) }

        do { heartRate = try await fetchRestingHR() }
        catch { print("[HealthKit] fetchRestingHR ERROR: \(error)"); heartRate = nil }

        do { avgHeartRate = try await fetchAvgHR(from: yesterday, to: now) }
        catch { print("[HealthKit] fetchAvgHR ERROR: \(error)"); avgHeartRate = nil }

        do { stepCount = try await fetchSteps(from: Calendar.current.startOfDay(for: now), to: now) }
        catch { print("[HealthKit] fetchSteps ERROR: \(error)"); stepCount = nil }

        do { oxygenSat = try await fetchSPO2() }
        catch { print("[HealthKit] fetchSPO2 ERROR: \(error)"); oxygenSat = nil }

        do { respiratoryRate = try await fetchRespiratoryRate() }
        catch { print("[HealthKit] fetchRespiratoryRate ERROR: \(error)"); respiratoryRate = nil }

        print("[HealthKit] rHR=\(heartRate ?? -1) avgHR=\(avgHeartRate ?? -1) sleep=\(sleepData.total ?? -1) steps=\(stepCount ?? -1) spo2=\(oxygenSat ?? -1)")

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
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let allSamples = (samples as? [HKCategorySample]) ?? []

                // 모든 소스 ID + 값 로그
                let sources = Set(allSamples.map { $0.sourceRevision.source.bundleIdentifier })
                print("[HealthKit] sleep sources: \(sources)")
                print("[HealthKit] sleep all values: \(allSamples.map { "\($0.value)(\($0.startDate)~\($0.endDate))" })")

                // asleep 계열만 필터 (inBed 제외)
                let asleepSamples = allSamples.filter {
                    let v = HKCategoryValueSleepAnalysis(rawValue: $0.value)
                    return v == .asleepDeep || v == .asleepREM || v == .asleepCore || v == .asleepUnspecified
                }

                let bySource = Dictionary(grouping: asleepSamples) { $0.sourceRevision.source.bundleIdentifier }
                print("[HealthKit] asleep by source: \(bySource.mapValues { $0.count })")

                // deep/rem을 가진 소스 우선 (Watch), 없으면 전체
                let detailedSource = bySource.first { src in
                    src.value.contains { HKCategoryValueSleepAnalysis(rawValue: $0.value) == .asleepDeep
                        || HKCategoryValueSleepAnalysis(rawValue: $0.value) == .asleepREM }
                }
                let candidateSamples = detailedSource?.value ?? asleepSamples

                // 가장 최근 수면 세션만 추출 (세션 간격 4시간 이상이면 별도 세션)
                let sorted = candidateSamples.sorted { $0.startDate < $1.startDate }
                var sessions: [[HKCategorySample]] = []
                for s in sorted {
                    if let lastSession = sessions.last,
                       let lastEnd = lastSession.last?.endDate,
                       s.startDate.timeIntervalSince(lastEnd) < 4 * 3600 {
                        sessions[sessions.count - 1].append(s)
                    } else {
                        sessions.append([s])
                    }
                }
                let latestSession = sessions.last ?? []
                print("[HealthKit] total sessions=\(sessions.count) latestSession samples=\(latestSession.count)")

                // 최근 세션 내 겹침 제거
                let sessionSorted = latestSession.sorted { $0.startDate < $1.startDate }
                var merged: [(start: Date, end: Date, value: Int)] = []
                for s in sessionSorted {
                    guard s.endDate > s.startDate else { continue }
                    if let last = merged.last, s.startDate < last.end {
                        merged[merged.count - 1].end = max(last.end, s.endDate)
                    } else {
                        merged.append((s.startDate, s.endDate, s.value))
                    }
                }

                var deep = 0.0, rem = 0.0, light = 0.0
                for seg in merged {
                    let hours = seg.end.timeIntervalSince(seg.start) / 3600
                    switch HKCategoryValueSleepAnalysis(rawValue: seg.value) {
                    case .asleepDeep:                     deep += hours
                    case .asleepREM:                      rem += hours
                    case .asleepUnspecified, .asleepCore: light += hours
                    default: break
                    }
                }
                let total = deep + rem + light
                print("[HealthKit] sleep total=\(String(format:"%.2f",total))h deep=\(String(format:"%.2f",deep)) rem=\(String(format:"%.2f",rem)) light=\(String(format:"%.2f",light)) all=\(allSamples.count)")
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
        let unit = HKUnit.count().unitDivided(by: .minute())
        // 최근 30일로 넓게 잡아서 가장 최근 값 가져오기
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                print("[HealthKit] restingHR=\(value ?? -1) samples=\(samples?.count ?? 0)")
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchAvgHR(from: Date, to: Date) async throws -> Double? {
        let type = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, error in
                if let error { continuation.resume(throwing: error); return }
                let value = stats?.averageQuantity()?.doubleValue(for: .count().unitDivided(by: .minute()))
                print("[HealthKit] avgHR=\(value ?? -1)")
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Steps

    private func fetchSteps(from: Date, to: Date) async throws -> Int? {
        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error { continuation.resume(throwing: error); return }
                let value = stats?.sumQuantity()?.doubleValue(for: .count())
                print("[HealthKit] steps=\(value ?? -1)")
                continuation.resume(returning: value.map { Int($0) })
            }
            store.execute(query)
        }
    }

    // MARK: - SpO2

    private func fetchSPO2() async throws -> Double? {
        let type = HKQuantityType(.oxygenSaturation)
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .percent())
                print("[HealthKit] spo2=\(value ?? -1)")
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Respiratory Rate

    private func fetchRespiratoryRate() async throws -> Double? {
        let type = HKQuantityType(.respiratoryRate)
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                print("[HealthKit] respiratoryRate=\(value ?? -1)")
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        "이 기기에서는 HealthKit을 사용할 수 없습니다."
    }
}
