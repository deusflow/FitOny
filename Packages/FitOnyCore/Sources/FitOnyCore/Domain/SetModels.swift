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

    public var workingSetCount: Int {
        switch self {
        case let .straightSets(count, _):
            return count
        case let .reversePyramid(steps):
            return steps.count
        case let .superset(_, count, _):
            return count
        case let .dropSet(workingSets, _, _):
            return workingSets
        }
    }

    public func repRange(forWorkingSetIndex index: Int) -> RepRange {
        switch self {
        case let .straightSets(_, reps),
             let .superset(_, _, reps),
             let .dropSet(_, reps, _):
            return reps
        case let .reversePyramid(steps):
            guard !steps.isEmpty else { return RepRange(min: 8, max: 10) }
            let clamped = min(max(0, index), steps.count - 1)
            return steps[clamped]
        }
    }
}

public enum WarmupPrescription: Codable, Sendable, Equatable {
    case none
    case single(percentageOfFirstWorking: Double, targetReps: Int)
    case pyramid(steps: [(percentage: Double, reps: Int)])

    public static let standardDoubleWarmup = WarmupPrescription.pyramid(steps: [
        (percentage: 0.50, reps: 12),
        (percentage: 0.75, reps: 8)
    ])

    public static func single12() -> WarmupPrescription {
        .single(percentageOfFirstWorking: 0.55, targetReps: 12)
    }

    public static func single10() -> WarmupPrescription {
        .single(percentageOfFirstWorking: 0.55, targetReps: 10)
    }

    private enum CodingKeys: String, CodingKey {
        case kind, percentage, reps, steps
    }

    private struct StepPair: Codable {
        let percentage: Double
        let reps: Int
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "none":
            self = .none
        case "single":
            let pct = try container.decode(Double.self, forKey: .percentage)
            let reps = try container.decode(Int.self, forKey: .reps)
            self = .single(percentageOfFirstWorking: pct, targetReps: reps)
        default:
            let pairs = try container.decode([StepPair].self, forKey: .steps)
            self = .pyramid(steps: pairs.map { ($0.percentage, $0.reps) })
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode("none", forKey: .kind)
        case let .single(pct, reps):
            try container.encode("single", forKey: .kind)
            try container.encode(pct, forKey: .percentage)
            try container.encode(reps, forKey: .reps)
        case let .pyramid(steps):
            try container.encode("pyramid", forKey: .kind)
            try container.encode(steps.map { StepPair(percentage: $0.percentage, reps: $0.reps) }, forKey: .steps)
        }
    }

    public static func == (lhs: WarmupPrescription, rhs: WarmupPrescription) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.single(p1, r1), .single(p2, r2)):
            return p1 == p2 && r1 == r2
        case let (.pyramid(s1), .pyramid(s2)):
            guard s1.count == s2.count else { return false }
            return zip(s1, s2).allSatisfy { $0.percentage == $1.percentage && $0.reps == $1.reps }
        default:
            return false
        }
    }
}

public struct TempoPrescription: Codable, Sendable, Equatable {
    public var eccentricSeconds: Double
    public var bottomPauseSeconds: Double
    public var topPauseSeconds: Double

    public static let controlledHypertrophy = TempoPrescription(
        eccentricSeconds: 2.5,
        bottomPauseSeconds: 0.5,
        topPauseSeconds: 0.0
    )

    public init(eccentricSeconds: Double, bottomPauseSeconds: Double, topPauseSeconds: Double = 0.0) {
        self.eccentricSeconds = eccentricSeconds
        self.bottomPauseSeconds = bottomPauseSeconds
        self.topPauseSeconds = topPauseSeconds
    }
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
