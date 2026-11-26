import Foundation

/// Живая телеметрия системной тренировки Apple Watch (`HKWorkoutSession`),
/// заменяющая необходимость параллельно запускать стандартное приложение «Тренировка».
public struct LiveWorkoutTelemetry: Codable, Sendable, Equatable {
    public var elapsedSeconds: Int
    public var currentHeartRateBPM: Int?
    public var activeKilocalories: Int
    public var totalKilocalories: Int
    public var isPaused: Bool

    public init(
        elapsedSeconds: Int,
        currentHeartRateBPM: Int? = nil,
        activeKilocalories: Int = 0,
        totalKilocalories: Int = 0,
        isPaused: Bool = false
    ) {
        self.elapsedSeconds = max(0, elapsedSeconds)
        self.currentHeartRateBPM = currentHeartRateBPM
        self.activeKilocalories = max(0, activeKilocalories)
        self.totalKilocalories = max(0, totalKilocalories)
        self.isPaused = isPaused
    }
}

/// Единый конверт событий для мгновенного Live Mirroring и гарантированной очереди WatchConnectivity.
public struct WatchSyncEnvelope: Codable, Sendable, Equatable, Identifiable {
    public enum Payload: Codable, Sendable, Equatable {
        case sessionStarted(sessionID: UUID, moduleID: UUID, startedAt: Date)
        case activeTargetUpdated(
            sessionID: UUID,
            exerciseID: UUID,
            equipmentVariant: EquipmentVariant,
            weightKg: Double,
            targetReps: Int
        )
        case setCompleted(sessionID: UUID, set: CompletedSetRecord)
        case restTimerAdjusted(sessionID: UUID, remainingSeconds: Int)
        case liveWorkoutTelemetryUpdated(sessionID: UUID, telemetry: LiveWorkoutTelemetry)
        case sessionFinished(sessionID: UUID, finishedAt: Date)
        case morningCheckInSubmitted(MorningCheckIn)
        case languageChanged(AppLanguage)
    }

    public var id: UUID
    public var createdAt: Date
    public var payload: Payload

    public init(id: UUID = UUID(), createdAt: Date = .now, payload: Payload) {
        self.id = id
        self.createdAt = createdAt
        self.payload = payload
    }
}
