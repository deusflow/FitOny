import Foundation
import FitOnyCore

/// Отладочные сценарии биометрии для проверки без живого iPhone и с пустым приложением «Здоровье» (День 8.2).
public enum DebugBiometricsPreset: String, Codable, Sendable, CaseIterable {
    case peakRecovery         // Отличный сон 8 ч, высокий HRV -> Readiness ~90
    case mildSleepDebt        // Недосып 5 ч 15 м + RHR +5 уд -> Умеренный спад
    case accumulatedOverreach // 4 дня подряд просадка HRV и высокий RHR -> Внеплановый Deload
    case suspectedIllness     // Острый скачок температуры +0.7°C, дыхания и пульса -> Подозрение на ОРВИ
    case sleptWithoutWatch    // Спал без часов -> пустые ночные сенсоры

    public var localizedTitle: LocalizedCopy {
        switch self {
        case .peakRecovery:
            LocalizedCopy(da: "Debug: Topform (8t søvn)", ru: "Отладка: Пик формы (8ч сна)")
        case .mildSleepDebt:
            LocalizedCopy(da: "Debug: Søvnunderskud (5t 15m)", ru: "Отладка: Недосып (5ч 15м)")
        case .accumulatedOverreach:
            LocalizedCopy(da: "Debug: 4 dages overtræning (Deload)", ru: "Отладка: 4 дня перегруза (Deload)")
        case .suspectedIllness:
            LocalizedCopy(da: "Debug: Feber / sygdomstegn (+0.7 °C)", ru: "Отладка: Признак ОРВИ (+0.7 °C)")
        case .sleptWithoutWatch:
            LocalizedCopy(da: "Debug: Sov uden ur", ru: "Отладка: Спал без часов")
        }
    }

    /// Генерирует реалистичную 14-дневную базовую линию + сегодняшний ночной срез под выбранный сценарий.
    public func makeHistoryAndToday(referenceMorning: Date = .now, calendar: Calendar = .current) -> (history: [NightBiometrics], today: NightBiometrics) {
        var history: [NightBiometrics] = []

        for daysBack in stride(from: 14, through: 1, by: -1) {
            let date = calendar.date(byAdding: .day, value: -daysBack, to: referenceMorning) ?? referenceMorning
            let isStrainedTail = (self == .accumulatedOverreach && daysBack <= 3)

            let jitter = Double((daysBack % 3) - 1)
            history.append(
                NightBiometrics(
                    date: date,
                    nocturnalHRVms: isStrainedTail ? 44.0 : (66.0 + jitter * 3.0),
                    restingHeartRateBPM: isStrainedTail ? 61.0 : (52.0 + jitter * 1.0),
                    sleepDurationMinutes: isStrainedTail ? 350 : 455,
                    deepAndREMMinutes: isStrainedTail ? 95 : 165,
                    wristTemperatureCelsius: 36.45 + jitter * 0.05,
                    respiratoryRateBrPM: 14.2 + jitter * 0.2
                )
            )
        }

        let today: NightBiometrics
        switch self {
        case .peakRecovery:
            today = NightBiometrics(
                date: referenceMorning,
                nocturnalHRVms: 78.0,
                restingHeartRateBPM: 49.0,
                sleepDurationMinutes: 485,
                deepAndREMMinutes: 190,
                wristTemperatureCelsius: 36.42,
                respiratoryRateBrPM: 14.0
            )
        case .mildSleepDebt:
            today = NightBiometrics(
                date: referenceMorning,
                nocturnalHRVms: 52.0,
                restingHeartRateBPM: 57.0,
                sleepDurationMinutes: 315,
                deepAndREMMinutes: 85,
                wristTemperatureCelsius: 36.55,
                respiratoryRateBrPM: 14.6
            )
        case .accumulatedOverreach:
            today = NightBiometrics(
                date: referenceMorning,
                nocturnalHRVms: 42.0,
                restingHeartRateBPM: 62.0,
                sleepDurationMinutes: 345,
                deepAndREMMinutes: 90,
                wristTemperatureCelsius: 36.50,
                respiratoryRateBrPM: 14.8
            )
        case .suspectedIllness:
            today = NightBiometrics(
                date: referenceMorning,
                nocturnalHRVms: 36.0,
                restingHeartRateBPM: 61.5,
                sleepDurationMinutes: 390,
                deepAndREMMinutes: 95,
                wristTemperatureCelsius: 37.18, // +0.73 °C к базовой медиане
                respiratoryRateBrPM: 16.9      // +2.7 вдоха/мин
            )
        case .sleptWithoutWatch:
            today = NightBiometrics(date: referenceMorning)
        }

        return (history, today)
    }
}

/// Абстракция поставщика медицинских данных Здоровья (позволяет подменять реальный HKHealthStore на отладочный источник).
public protocol HealthBiometricsProviding: Sendable {
    var isHealthDataAvailable: Bool { get }
    func requestPermissions() async throws
    func fetchNightBiometrics(for morningDate: Date) async throws -> NightBiometrics
    func fetchRecentBloodPressure(days: Int) async throws -> [BloodPressureReading]
    func saveBloodPressure(_ reading: BloodPressureReading) async throws
    func saveCompletedStrengthWorkout(
        startedAt: Date,
        finishedAt: Date,
        activeKilocalories: Double?
    ) async throws
}
