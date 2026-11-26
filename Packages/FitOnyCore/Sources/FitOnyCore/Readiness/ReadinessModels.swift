import Foundation

public enum ReadinessZone: String, Codable, Sendable, Equatable {
    case peak            // 85–100: Пик восстановления
    case normal          // 55–84: Рабочая норма
    case moderateDip     // 40–54: Умеренный спад (только совет, без авто-сброса веса)
    case criticalFatigue // 0–39: Сильное недовосстановление

    public var localizedName: LocalizedCopy {
        switch self {
        case .peak:
            LocalizedCopy(da: "Topform", ru: "Пик восстановления")
        case .normal:
            LocalizedCopy(da: "Normal klar", ru: "Рабочая норма")
        case .moderateDip:
            LocalizedCopy(da: "Let træthed", ru: "Умеренный спад")
        case .criticalFatigue:
            LocalizedCopy(da: "Høj træthed", ru: "Сильное утомление")
        }
    }
}

public struct NightBiometrics: Codable, Sendable, Equatable {
    public var date: Date
    public var nocturnalHRVms: Double?
    public var restingHeartRateBPM: Double?
    public var sleepDurationMinutes: Int?
    public var deepAndREMMinutes: Int?
    public var wristTemperatureCelsius: Double?
    public var respiratoryRateBrPM: Double?

    public init(
        date: Date,
        nocturnalHRVms: Double? = nil,
        restingHeartRateBPM: Double? = nil,
        sleepDurationMinutes: Int? = nil,
        deepAndREMMinutes: Int? = nil,
        wristTemperatureCelsius: Double? = nil,
        respiratoryRateBrPM: Double? = nil
    ) {
        self.date = date
        self.nocturnalHRVms = nocturnalHRVms
        self.restingHeartRateBPM = restingHeartRateBPM
        self.sleepDurationMinutes = sleepDurationMinutes
        self.deepAndREMMinutes = deepAndREMMinutes
        self.wristTemperatureCelsius = wristTemperatureCelsius
        self.respiratoryRateBrPM = respiratoryRateBrPM
    }
}

public struct MorningCheckIn: Codable, Sendable, Equatable {
    public var energyRating: Int     // 1..5
    public var sorenessRating: Int   // 1..5 (1 = нет крепатуры, 5 = сильная крепатура)
    public var stressRating: Int     // 1..5 (1 = спокоен, 5 = высокий стресс)
    public var recordedAt: Date

    public init(energyRating: Int, sorenessRating: Int, stressRating: Int, recordedAt: Date = .now) {
        self.energyRating = min(5, max(1, energyRating))
        self.sorenessRating = min(5, max(1, sorenessRating))
        self.stressRating = min(5, max(1, stressRating))
        self.recordedAt = recordedAt
    }
}

/// Индекс готовности работает исключительно как советник и никогда не меняет веса без согласия пользователя.
public struct ReadinessSnapshot: Codable, Sendable, Equatable {
    public var date: Date
    public var score: Int            // 0..100
    public var zone: ReadinessZone
    public var hasCompleteNightSensors: Bool
    public var isCalibratingBaseline: Bool
    public var isSuspectedIllness: Bool
    public var shouldSuggestUnplannedDeload: Bool
    public var advisoryNote: LocalizedCopy?

    public init(
        date: Date = .now,
        score: Int,
        hasCompleteNightSensors: Bool,
        isCalibratingBaseline: Bool = false,
        isSuspectedIllness: Bool = false,
        shouldSuggestUnplannedDeload: Bool = false,
        advisoryNote: LocalizedCopy? = nil
    ) {
        let clamped = min(100, max(0, score))
        self.date = date
        self.score = clamped
        if clamped >= 85 {
            self.zone = .peak
        } else if clamped >= 55 {
            self.zone = .normal
        } else if clamped >= 40 {
            self.zone = .moderateDip
        } else {
            self.zone = .criticalFatigue
        }
        self.hasCompleteNightSensors = hasCompleteNightSensors
        self.isCalibratingBaseline = isCalibratingBaseline
        self.isSuspectedIllness = isSuspectedIllness
        self.shouldSuggestUnplannedDeload = shouldSuggestUnplannedDeload
        self.advisoryNote = advisoryNote
    }
}
