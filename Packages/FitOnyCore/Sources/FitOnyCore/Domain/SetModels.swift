import Foundation

public struct RepRange: Codable, Sendable, Equatable {
    public var min: Int
    public var max: Int

    public init(min: Int, max: Int) {
        precondition(min > 0 && max >= min, "RepRange requires 0 < min <= max")
        self.min = min
        self.max = max
    }
}

public enum SetScheme: Codable, Sendable, Equatable {
    case straightSets(count: Int, reps: RepRange)
    case reversePyramid(steps: [RepRange])
    case superset(pairedExerciseID: UUID, count: Int, reps: RepRange)
    case dropSet(workingSets: Int, reps: RepRange, dropSteps: Int)
}

/// Разделение закреплённого базового веса атлета и эффективного веса текущей сессии.
public struct ExerciseLoadState: Codable, Sendable, Equatable {
    public var exerciseID: UUID
    public var baselineWorkingWeightKg: Double
    public var sessionTargetWeightKg: Double

    public init(
        exerciseID: UUID,
        baselineWorkingWeightKg: Double,
        sessionTargetWeightKg: Double? = nil
    ) {
        self.exerciseID = exerciseID
        self.baselineWorkingWeightKg = baselineWorkingWeightKg
        self.sessionTargetWeightKg = sessionTargetWeightKg ?? baselineWorkingWeightKg
    }
}

public struct CompletedSetRecord: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var exerciseID: UUID
    public var setIndex: Int
    public var isWarmup: Bool
    public var weightKg: Double
    public var completedReps: Int
    public var rir: Int
    public var peakHeartRate: Int?
    public var hrr60Drop: Int?
    public var concentricSlowdownPercent: Double?
    public var completedAt: Date

    public init(
        id: UUID = UUID(),
        exerciseID: UUID,
        setIndex: Int,
        isWarmup: Bool,
        weightKg: Double,
        completedReps: Int,
        rir: Int,
        peakHeartRate: Int? = nil,
        hrr60Drop: Int? = nil,
        concentricSlowdownPercent: Double? = nil,
        completedAt: Date = .now
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.setIndex = setIndex
        self.isWarmup = isWarmup
        self.weightKg = weightKg
        self.completedReps = completedReps
        self.rir = rir
        self.peakHeartRate = peakHeartRate
        self.hrr60Drop = hrr60Drop
        self.concentricSlowdownPercent = concentricSlowdownPercent
        self.completedAt = completedAt
    }
}
