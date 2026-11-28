import Foundation
import FitOnyCore

/// Тип стадии сна, приведённый к платформенно-независимому виду для фильтрации и тестов.
public enum SleepStageKind: String, Codable, Sendable, Equatable {
    case inBed
    case awake
    case asleepUnspecified
    case asleepCore
    case asleepDeep
    case asleepREM

    public var countsAsAsleep: Bool {
        switch self {
        case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
            return true
        case .inBed, .awake:
            return false
        }
    }

    public var isRestorativeDeepOrREM: Bool {
        self == .asleepDeep || self == .asleepREM
    }
}

/// Одиночный интервал стадии сна из Apple Health.
public struct RawSleepInterval: Codable, Sendable, Equatable {
    public var start: Date
    public var end: Date
    public var stage: SleepStageKind

    public init(start: Date, end: Date, stage: SleepStageKind) {
        self.start = start
        self.end = max(start, end)
        self.stage = stage
    }
}

/// Точечный или интервальный числовой замер из Apple Health (HRV, RHR, температура, дыхание).
public struct TimedQuantitySample: Codable, Sendable, Equatable {
    public var timestamp: Date
    public var value: Double

    public init(timestamp: Date, value: Double) {
        self.timestamp = timestamp
        self.value = value
    }
}

/// Детерминированный агрегатор сырых сэмплов HealthKit:
/// склеивает пересекающиеся интервалы сна (защита от двойного счёта часов + телефона)
/// и отбирает замеры HRV/дыхания строго внутри реальных фаз сна.
public enum HealthSampleAggregator {
    public static func buildNightBiometrics(
        for morningDate: Date,
        sleepIntervals: [RawSleepInterval],
        hrvSamplesMs: [TimedQuantitySample],
        restingHeartRateSamplesBPM: [TimedQuantitySample],
        sleepingHeartRateSamplesBPM: [TimedQuantitySample] = [],
        wristTemperatureSamplesCelsius: [TimedQuantitySample],
        respiratoryRateSamplesBrPM: [TimedQuantitySample]
    ) -> NightBiometrics {
        let asleepRaw = sleepIntervals.filter { $0.stage.countsAsAsleep && $0.end > $0.start }
        let mergedAsleep = mergeOverlappingIntervals(asleepRaw.map { ($0.start, $0.end) })

        let restorativeRaw = sleepIntervals.filter { $0.stage.isRestorativeDeepOrREM && $0.end > $0.start }
        let mergedRestorative = mergeOverlappingIntervals(restorativeRaw.map { ($0.start, $0.end) })

        let totalAsleepSeconds = mergedAsleep.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
        let restorativeSeconds = mergedRestorative.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }

        let sleepMinutes: Int? = totalAsleepSeconds > 0 ? Int((totalAsleepSeconds / 60.0).rounded()) : nil
        let deepREMMinutes: Int? = totalAsleepSeconds > 0
            ? min(sleepMinutes ?? 0, Int((restorativeSeconds / 60.0).rounded()))
            : nil

        // Фильтруем HRV строго по интервалам фактического сна; если стадии сна не записаны — берём ночное окно (22:00..09:00)
        let filteredHRV = filterSamples(hrvSamplesMs, inside: mergedAsleep).filter { $0.value > 0 }
        let medianHRV = median(of: filteredHRV.map(\.value))

        // Пульс покоя: приоритет системному restingHeartRate, резерв — 10-й перцентиль ночного пульса во сне
        let rhrValue: Double? = {
            let validRHR = restingHeartRateSamplesBPM.filter { $0.value > 25 && $0.value < 220 }
            if let latestRHR = validRHR.max(by: { $0.timestamp < $1.timestamp })?.value {
                return (latestRHR * 10.0).rounded() / 10.0
            }
            let asleepHR = filterSamples(sleepingHeartRateSamplesBPM, inside: mergedAsleep)
                .map(\.value)
                .filter { $0 > 25 && $0 < 220 }
                .sorted()
            guard !asleepHR.isEmpty else { return nil }
            let idx = min(asleepHR.count - 1, max(0, Int(Double(asleepHR.count - 1) * 0.10)))
            return (asleepHR[idx] * 10.0).rounded() / 10.0
        }()

        let wristTemp = wristTemperatureSamplesCelsius
            .max(by: { $0.timestamp < $1.timestamp })?
            .value

        let filteredResp = filterSamples(respiratoryRateSamplesBrPM, inside: mergedAsleep).filter { $0.value > 0 }
        let medianResp = median(of: filteredResp.map(\.value))

        return NightBiometrics(
            date: morningDate,
            nocturnalHRVms: medianHRV,
            restingHeartRateBPM: rhrValue,
            sleepDurationMinutes: sleepMinutes,
            deepAndREMMinutes: deepREMMinutes,
            wristTemperatureCelsius: wristTemp,
            respiratoryRateBrPM: medianResp
        )
    }

    /// Склеивает накладывающиеся друг на друга отрезки времени, чтобы часы + iPhone не удваивали часы сна.
    public static func mergeOverlappingIntervals(
        _ intervals: [(start: Date, end: Date)]
    ) -> [(start: Date, end: Date)] {
        let valid = intervals
            .filter { $0.end > $0.start }
            .sorted { $0.start < $1.start }

        guard var current = valid.first else { return [] }
        var merged: [(start: Date, end: Date)] = []

        for next in valid.dropFirst() {
            if next.start <= current.end {
                if next.end > current.end {
                    current.end = next.end
                }
            } else {
                merged.append(current)
                current = next
            }
        }
        merged.append(current)
        return merged
    }

    private static func filterSamples(
        _ samples: [TimedQuantitySample],
        inside sleepWindows: [(start: Date, end: Date)]
    ) -> [TimedQuantitySample] {
        guard !sleepWindows.isEmpty else {
            return samples
        }
        return samples.filter { sample in
            sleepWindows.contains { window in
                sample.timestamp >= window.start && sample.timestamp <= window.end
            }
        }
    }

    private static func median(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        let raw: Double
        if sorted.count % 2 == 1 {
            raw = sorted[mid]
        } else {
            raw = (sorted[mid - 1] + sorted[mid]) / 2.0
        }
        return (raw * 10.0).rounded() / 10.0
    }
}
