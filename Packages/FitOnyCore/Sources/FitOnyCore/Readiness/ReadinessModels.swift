import Foundation

public struct MorningCheckIn: Codable, Sendable, Equatable {
    public var energyRating: Int     // 1..5
    public var sorenessRating: Int   // 1..5
    public var stressRating: Int     // 1..5
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
    public var hasCompleteNightSensors: Bool
    public var isSuspectedIllness: Bool
    public var advisoryNote: LocalizedCopy?

    public init(
        date: Date = .now,
        score: Int,
        hasCompleteNightSensors: Bool,
        isSuspectedIllness: Bool = false,
        advisoryNote: LocalizedCopy? = nil
    ) {
        self.date = date
        self.score = min(100, max(0, score))
        self.hasCompleteNightSensors = hasCompleteNightSensors
        self.isSuspectedIllness = isSuspectedIllness
        self.advisoryNote = advisoryNote
    }
}
