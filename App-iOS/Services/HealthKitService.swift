import Foundation
import HealthKit
import Observation
import FitOnyCore
import FitOnyStorage

/// Системный адаптер Apple HealthKit (принцип минимальных прав + защита от двойного счёта фаз сна).
struct AppleHealthKitProvider: HealthBiometricsProviding {
    private let healthStore = HKHealthStore()

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestPermissions() async throws {
        guard isHealthDataAvailable else { return }

        // Важно: HKCorrelationType(.bloodPressure) нельзя передавать напрямую в requestAuthorization —
        // HealthKit требует запрашивать его компоненты (systolic + diastolic) по отдельности.
        let shareTypes: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic)
        ]

        let readTypes: Set<HKObjectType> = [
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.heartRate),
            HKQuantityType(.appleSleepingWristTemperature),
            HKQuantityType(.respiratoryRate),
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic)
        ]

        try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
    }

    func fetchNightBiometrics(for morningDate: Date) async throws -> NightBiometrics {
        guard isHealthDataAvailable else {
            return NightBiometrics(date: morningDate)
        }

        // Ночное окно поиска: с 18:00 вчерашнего вечера до 12:00 сегодняшнего дня
        let calendar = Calendar.current
        let noonToday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: morningDate) ?? morningDate
        let windowEnd = min(morningDate, noonToday.addingTimeInterval(3 * 3600))
        let windowStart = calendar.date(byAdding: .hour, value: -18, to: windowEnd) ?? windowEnd.addingTimeInterval(-18 * 3600)

        async let sleepIntervals = querySleepIntervals(start: windowStart, end: windowEnd)
        async let hrvSamples = queryQuantitySamples(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: windowStart, end: windowEnd)
        async let rhrSamples = queryQuantitySamples(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: windowStart, end: windowEnd)
        async let hrSamples = queryQuantitySamples(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: windowStart, end: windowEnd)
        async let tempSamples = queryQuantitySamples(.appleSleepingWristTemperature, unit: .degreeCelsius(), start: windowStart, end: windowEnd)
        async let respSamples = queryQuantitySamples(.respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()), start: windowStart, end: windowEnd)

        return try await HealthSampleAggregator.buildNightBiometrics(
            for: morningDate,
            sleepIntervals: sleepIntervals,
            hrvSamplesMs: hrvSamples,
            restingHeartRateSamplesBPM: rhrSamples,
            sleepingHeartRateSamplesBPM: hrSamples,
            wristTemperatureSamplesCelsius: tempSamples,
            respiratoryRateSamplesBrPM: respSamples
        )
    }

    func fetchRecentBloodPressure(days: Int) async throws -> [BloodPressureReading] {
        guard isHealthDataAvailable else { return [] }

        let end = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -max(1, days), to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.correlation(type: HKCorrelationType(.bloodPressure), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let correlations = try await descriptor.result(for: healthStore)
        let mmHg = HKUnit.millimeterOfMercury()
        let systolicType = HKQuantityType(.bloodPressureSystolic)
        let diastolicType = HKQuantityType(.bloodPressureDiastolic)

        var readings: [BloodPressureReading] = []
        for corr in correlations {
            guard let sysSample = corr.objects(for: systolicType).first as? HKQuantitySample,
                  let diaSample = corr.objects(for: diastolicType).first as? HKQuantitySample else {
                continue
            }
            let sys = Int(sysSample.quantity.doubleValue(for: mmHg).rounded())
            let dia = Int(diaSample.quantity.doubleValue(for: mmHg).rounded())
            let hour = Calendar.current.component(.hour, from: corr.startDate)
            let slot: BloodPressureReading.TimeOfDaySlot = hour < 11 ? .morningFasted : (hour < 17 ? .afternoon : .evening)

            readings.append(
                BloodPressureReading(
                    id: corr.uuid,
                    recordedAt: corr.startDate,
                    systolicMMHg: sys,
                    diastolicMMHg: dia,
                    timeSlot: slot,
                    syncedToHealthKit: true
                )
            )
        }
        return readings
    }

    func saveBloodPressure(_ reading: BloodPressureReading) async throws {
        guard isHealthDataAvailable else { return }

        let mmHg = HKUnit.millimeterOfMercury()
        let sysQty = HKQuantity(unit: mmHg, doubleValue: Double(reading.systolicMMHg))
        let diaQty = HKQuantity(unit: mmHg, doubleValue: Double(reading.diastolicMMHg))

        let sysSample = HKQuantitySample(
            type: HKQuantityType(.bloodPressureSystolic),
            quantity: sysQty,
            start: reading.recordedAt,
            end: reading.recordedAt
        )
        let diaSample = HKQuantitySample(
            type: HKQuantityType(.bloodPressureDiastolic),
            quantity: diaQty,
            start: reading.recordedAt,
            end: reading.recordedAt
        )

        let correlation = HKCorrelation(
            type: HKCorrelationType(.bloodPressure),
            start: reading.recordedAt,
            end: reading.recordedAt,
            objects: [sysSample, diaSample]
        )
        try await healthStore.save(correlation)
    }

    func saveCompletedStrengthWorkout(
        startedAt: Date,
        finishedAt: Date,
        activeKilocalories: Double?
    ) async throws {
        guard isHealthDataAvailable else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: config, device: .local())
        try await builder.beginCollection(at: startedAt)

        if let kcal = activeKilocalories, kcal > 0 {
            let energySample = HKCumulativeQuantitySample(
                type: HKQuantityType(.activeEnergyBurned),
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal),
                start: startedAt,
                end: max(startedAt, finishedAt)
            )
            try await builder.addSamples([energySample])
        }

        try await builder.endCollection(at: max(startedAt, finishedAt))
        _ = try await builder.finishWorkout()
    }

    private func querySleepIntervals(start: Date, end: Date) async throws -> [RawSleepInterval] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        let samples = try await descriptor.result(for: healthStore)
        return samples.compactMap { sample in
            guard let stage = mapSleepStage(sample.value) else { return nil }
            return RawSleepInterval(start: sample.startDate, end: sample.endDate, stage: stage)
        }
    }

    private func queryQuantitySamples(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> [TimedQuantitySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(identifier), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        let samples = try await descriptor.result(for: healthStore)
        return samples.map {
            TimedQuantitySample(timestamp: $0.startDate, value: $0.quantity.doubleValue(for: unit))
        }
    }

    private func mapSleepStage(_ rawValue: Int) -> SleepStageKind? {
        guard let hkValue = HKCategoryValueSleepAnalysis(rawValue: rawValue) else {
            return nil
        }
        switch hkValue {
        case .inBed:
            return .inBed
        case .awake:
            return .awake
        case .asleepUnspecified:
            return .asleepUnspecified
        case .asleepCore:
            return .asleepCore
        case .asleepDeep:
            return .asleepDeep
        case .asleepREM:
            return .asleepREM
        @unknown default:
            return .asleepUnspecified
        }
    }
}

/// Реактивный сервис Здоровья для экранов iPhone с поддержкой как реального HealthKit, так и отладочных пресетов (День 8).
@MainActor
@Observable
final class HealthKitService {
    private let provider: any HealthBiometricsProviding

    private(set) var latestReadiness: ReadinessSnapshot?
    private(set) var activeDebugPreset: DebugBiometricsPreset?
    private(set) var isSyncing = false
    private(set) var lastErrorMessage: String?

    init(provider: any HealthBiometricsProviding = AppleHealthKitProvider()) {
        self.provider = provider
    }

    var isHealthAvailable: Bool {
        provider.isHealthDataAvailable
    }

    func requestAuthorizationAndSync(into store: FitOnyStore) async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await provider.requestPermissions()
            if let preset = activeDebugPreset {
                latestReadiness = try ReadinessSyncCoordinator.applyDebugPreset(preset, into: store)
            } else {
                latestReadiness = try await ReadinessSyncCoordinator.refreshTodayReadiness(
                    using: provider,
                    store: store
                )
            }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func selectDebugPreset(_ preset: DebugBiometricsPreset?, into store: FitOnyStore) {
        activeDebugPreset = preset
        guard let preset else { return }
        do {
            latestReadiness = try ReadinessSyncCoordinator.applyDebugPreset(preset, into: store)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func fetchBloodPressureHistory(days: Int = 30) async -> [BloodPressureReading] {
        (try? await provider.fetchRecentBloodPressure(days: days)) ?? []
    }

    func exportBloodPressureToHealth(_ reading: BloodPressureReading) async throws {
        try await provider.saveBloodPressure(reading)
    }

    func exportStrengthWorkoutToHealth(startedAt: Date, finishedAt: Date, activeKilocalories: Double?) async throws {
        try await provider.saveCompletedStrengthWorkout(
            startedAt: startedAt,
            finishedAt: finishedAt,
            activeKilocalories: activeKilocalories
        )
    }
}
