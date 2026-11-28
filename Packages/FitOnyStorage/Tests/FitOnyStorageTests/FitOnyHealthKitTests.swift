import Foundation
import Testing
import FitOnyCore
@testable import FitOnyStorage

private struct MockHealthProvider: HealthBiometricsProviding {
    var isHealthDataAvailable: Bool = true
    var nightToReturn: NightBiometrics

    func requestPermissions() async throws {}
    func fetchNightBiometrics(for morningDate: Date) async throws -> NightBiometrics {
        nightToReturn
    }
    func fetchRecentBloodPressure(days: Int) async throws -> [BloodPressureReading] { [] }
    func saveBloodPressure(_ reading: BloodPressureReading) async throws {}
    func saveCompletedStrengthWorkout(startedAt: Date, finishedAt: Date, activeKilocalories: Double?) async throws {}
}

@MainActor
@Suite("HealthKit Aggregation & Debug Biometrics (Day 8)")
struct FitOnyHealthKitTests {
    @Test("Sleep interval merger prevents double-counting overlapping Watch + iPhone sleep samples and filters daytime HRV")
    func sleepDeduplicationAndAsleepOnlyHRV() {
        let base = Date(timeIntervalSince1970: 1_760_000_000)
        func offsetHours(_ h: Double) -> Date { base.addingTimeInterval(h * 3600.0) }

        // Пересекающиеся записи от часов и телефона за одну и ту же ночь (23:00..07:00 = 8 ч, но с пробуждением 03:00..03:30)
        let intervals: [RawSleepInterval] = [
            RawSleepInterval(start: offsetHours(0.0), end: offsetHours(8.5), stage: .inBed),          // не должен идти в сон
            RawSleepInterval(start: offsetHours(0.5), end: offsetHours(3.0), stage: .asleepCore),     // 2.5 ч
            RawSleepInterval(start: offsetHours(1.0), end: offsetHours(2.5), stage: .asleepDeep),     // дубль внутри Core + 1.5 ч Deep
            RawSleepInterval(start: offsetHours(3.0), end: offsetHours(3.5), stage: .awake),          // пробуждение 30 мин
            RawSleepInterval(start: offsetHours(3.5), end: offsetHours(7.5), stage: .asleepREM),      // 4.0 ч REM
            RawSleepInterval(start: offsetHours(4.0), end: offsetHours(7.5), stage: .asleepUnspecified) // дубль от iPhone
        ]

        // Дневной замер HRV (за пределами сна — после кофе, 18 мс) не должен испортить ночную медиану (68 мс)
        let hrvSamples: [TimedQuantitySample] = [
            TimedQuantitySample(timestamp: offsetHours(-3.0), value: 18.0), // день — отбросится!
            TimedQuantitySample(timestamp: offsetHours(1.5), value: 66.0),
            TimedQuantitySample(timestamp: offsetHours(5.0), value: 70.0),
            TimedQuantitySample(timestamp: offsetHours(10.0), value: 22.0)  // утро после подъёма — отбросится!
        ]

        let night = HealthSampleAggregator.buildNightBiometrics(
            for: offsetHours(8.0),
            sleepIntervals: intervals,
            hrvSamplesMs: hrvSamples,
            restingHeartRateSamplesBPM: [],
            sleepingHeartRateSamplesBPM: [
                TimedQuantitySample(timestamp: offsetHours(2.0), value: 49.0),
                TimedQuantitySample(timestamp: offsetHours(5.0), value: 52.0)
            ],
            wristTemperatureSamplesCelsius: [TimedQuantitySample(timestamp: offsetHours(6.0), value: 36.48)],
            respiratoryRateSamplesBrPM: [TimedQuantitySample(timestamp: offsetHours(4.5), value: 14.2)]
        )

        // Фактический сон: (0.5..3.0 = 150 мин) + (3.5..7.5 = 240 мин) = ровно 390 мин (а не 630 мин при наивном сложении!)
        #expect(night.sleepDurationMinutes == 390)
        // Deep (1.0..2.5 = 90 мин) + REM (3.5..7.5 = 240 мин) = 330 мин
        #expect(night.deepAndREMMinutes == 330)
        // Ночная медиана HRV (66 и 70 -> 68.0), дневные 18 и 22 отсечены
        #expect(night.nocturnalHRVms == 68.0)
        // Резервный расчёт пульса покоя по 10-му перцентилю сна
        #expect(night.restingHeartRateBPM == 49.0)
    }

    @Test("DebugBiometricsPreset scenarios produce expected Readiness states without a real iPhone")
    func debugPresetsProduceAccurateReadinessZones() throws {
        let store = try FitOnyStore.makeInMemoryStore()
        let morning = Date.now

        let peak = try ReadinessSyncCoordinator.applyDebugPreset(.peakRecovery, into: store, referenceDate: morning)
        #expect(peak.score >= 82)
        #expect(peak.isSuspectedIllness == false)
        #expect(peak.shouldSuggestUnplannedDeload == false)

        let illnessStore = try FitOnyStore.makeInMemoryStore()
        let illness = try ReadinessSyncCoordinator.applyDebugPreset(.suspectedIllness, into: illnessStore, referenceDate: morning)
        #expect(illness.isSuspectedIllness == true)
        #expect(illness.score <= 32)

        let overreachStore = try FitOnyStore.makeInMemoryStore()
        let overreach = try ReadinessSyncCoordinator.applyDebugPreset(.accumulatedOverreach, into: overreachStore, referenceDate: morning)
        #expect(overreach.shouldSuggestUnplannedDeload == true)

        let noWatchStore = try FitOnyStore.makeInMemoryStore()
        try noWatchStore.recordMorningCheckIn(
            MorningCheckIn(energyRating: 4, sorenessRating: 2, stressRating: 2, recordedAt: morning)
        )
        let noWatch = try ReadinessSyncCoordinator.applyDebugPreset(.sleptWithoutWatch, into: noWatchStore, referenceDate: morning)
        #expect(noWatch.hasCompleteNightSensors == false)
        #expect(noWatch.score >= 60)
    }

    @Test("ReadinessSyncCoordinator refreshes from HealthBiometricsProviding and caches widget score")
    func liveProviderRefreshPersistsAndCachesScore() async throws {
        let store = try FitOnyStore.makeInMemoryStore()
        let now = Date.now
        let mockNight = NightBiometrics(
            date: now,
            nocturnalHRVms: 72.0,
            restingHeartRateBPM: 50.0,
            sleepDurationMinutes: 470,
            deepAndREMMinutes: 175
        )
        let snapshot = try await ReadinessSyncCoordinator.refreshTodayReadiness(
            using: MockHealthProvider(nightToReturn: mockNight),
            store: store,
            referenceDate: now
        )

        #expect(try store.fetchNightBiometrics(days: 3, endingAt: now).count == 1)
        #expect(SharedDefaults.store.integer(forKey: SharedDefaults.Keys.cachedReadinessScore) == snapshot.score)
    }
}
