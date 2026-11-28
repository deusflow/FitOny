import Foundation
import FitOnyCore

/// Координирует загрузку ночной биометрии (из живого HealthKit или отладочного пресета),
/// сохранение в SwiftData, расчёт `ReadinessSnapshot` и публикацию балла в `SharedDefaults` для виджетов.
@MainActor
public enum ReadinessSyncCoordinator {
    /// Загружает сегодняшнюю ночь (и недостающий хвост истории при необходимости), сохраняет в базу и считает готовность.
    @discardableResult
    public static func refreshTodayReadiness(
        using provider: any HealthBiometricsProviding,
        store: FitOnyStore,
        referenceDate: Date = .now,
        targetSleepMinutes: Int = 450
    ) async throws -> ReadinessSnapshot {
        let todayBiometrics = try await provider.fetchNightBiometrics(for: referenceDate)
        try store.recordNightBiometrics(todayBiometrics)
        return try evaluateFromStore(
            store: store,
            todayBiometrics: todayBiometrics,
            referenceDate: referenceDate,
            targetSleepMinutes: targetSleepMinutes
        )
    }

    /// Подставляет готовый отладочный сценарий (День 8.2) прямо в локальную базу и пересчитывает готовность без iPhone.
    @discardableResult
    public static func applyDebugPreset(
        _ preset: DebugBiometricsPreset,
        into store: FitOnyStore,
        referenceDate: Date = .now,
        targetSleepMinutes: Int = 450
    ) throws -> ReadinessSnapshot {
        let generated = preset.makeHistoryAndToday(referenceMorning: referenceDate)
        for night in generated.history {
            try store.recordNightBiometrics(night)
        }
        try store.recordNightBiometrics(generated.today)

        return try evaluateFromStore(
            store: store,
            todayBiometrics: generated.today,
            referenceDate: referenceDate,
            targetSleepMinutes: targetSleepMinutes
        )
    }

    public static func evaluateFromStore(
        store: FitOnyStore,
        todayBiometrics: NightBiometrics? = nil,
        referenceDate: Date = .now,
        targetSleepMinutes: Int = 450
    ) throws -> ReadinessSnapshot {
        let history = try store.fetchNightBiometrics(days: 29, endingAt: referenceDate)
        let today = todayBiometrics ?? history.last ?? NightBiometrics(date: referenceDate)
        let checkIn = try store.fetchMorningCheckIn(for: referenceDate)

        let snapshot = ReadinessEngine.evaluate(
            today: today,
            historyLast28Days: history,
            checkIn: checkIn,
            targetSleepMinutes: targetSleepMinutes
        )

        SharedDefaults.store.set(snapshot.score, forKey: SharedDefaults.Keys.cachedReadinessScore)
        return snapshot
    }
}
