import Foundation

public struct IMUSample: Codable, Sendable, Equatable {
    public var timestamp: TimeInterval
    /// Вертикальная проекция ускорения запястья (в единицах g, очищенная от статики гравитации).
    public var verticalUserAccelerationG: Double

    public init(timestamp: TimeInterval, verticalUserAccelerationG: Double) {
        self.timestamp = timestamp
        self.verticalUserAccelerationG = verticalUserAccelerationG
    }
}

/// Ненавязчивый чип подсказки датчика на часах: не перетирает ввод на Digital Crown автоматически.
public struct SensorRepSuggestion: Codable, Sendable, Equatable {
    public var detectedReps: Int
    public var concentricSlowdownPercent: Double

    public init(detectedReps: Int, concentricSlowdownPercent: Double) {
        self.detectedReps = detectedReps
        self.concentricSlowdownPercent = concentricSlowdownPercent
    }
}
