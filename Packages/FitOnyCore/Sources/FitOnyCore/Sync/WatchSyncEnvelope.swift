import Foundation

/// Единый конверт событий для мгновенного Live Mirroring и гарантированной очереди WatchConnectivity.
public struct WatchSyncEnvelope: Codable, Sendable, Equatable, Identifiable {
    public enum Payload: Codable, Sendable, Equatable {
        case sessionStarted(sessionID: UUID, moduleID: UUID, startedAt: Date)
        case activeTargetUpdated(sessionID: UUID, exerciseID: UUID, weightKg: Double, targetReps: Int)
        case setCompleted(sessionID: UUID, set: CompletedSetRecord)
        case restTimerAdjusted(sessionID: UUID, remainingSeconds: Int)
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
