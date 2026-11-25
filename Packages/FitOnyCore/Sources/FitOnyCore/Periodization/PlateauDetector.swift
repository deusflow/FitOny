import Foundation

public struct WeeklyExercisePerformance: Codable, Sendable, Equatable {
    public var weekNumber: Int
    public var bestE1RMKg: Double
    public var averageReadinessScore: Int

    public init(weekNumber: Int, bestE1RMKg: Double, averageReadinessScore: Int) {
        self.weekNumber = weekNumber
        self.bestE1RMKg = bestE1RMKg
        self.averageReadinessScore = averageReadinessScore
    }
}

public struct BlockShiftRecommendation: Codable, Sendable, Equatable {
    public var exerciseID: UUID
    public var exerciseName: BilingualText
    public var stagnationWeeks: Int
    public var e1RMDeltaPercent: Double
    public var message: LocalizedCopy

    public init(
        exerciseID: UUID,
        exerciseName: BilingualText,
        stagnationWeeks: Int,
        e1RMDeltaPercent: Double,
        message: LocalizedCopy
    ) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.stagnationWeeks = stagnationWeeks
        self.e1RMDeltaPercent = e1RMDeltaPercent
        self.message = message
    }
}

public enum PlateauDetector {
    /// Фиксирует плато, если расчётный максимум e1RM в упражнении не вырос более чем на 0.5% за 3 недели подряд
    /// при нормальном среднем восстановлении (Readiness >= 60).
    public static func evaluate(
        exercise: ExerciseDefinition,
        weeklyHistory: [WeeklyExercisePerformance],
        minimumWeeksRequired: Int = 3,
        minimumAverageReadiness: Int = 60,
        growthThresholdPercent: Double = 0.5
    ) -> BlockShiftRecommendation? {
        let sorted = weeklyHistory.sorted { $0.weekNumber < $1.weekNumber }
        guard sorted.count >= minimumWeeksRequired else { return nil }

        let window = Array(sorted.suffix(minimumWeeksRequired))
        guard let first = window.first, let last = window.last, first.bestE1RMKg > 0 else {
            return nil
        }

        let avgReadiness = Double(window.map(\.averageReadinessScore).reduce(0, +)) / Double(window.count)
        guard avgReadiness >= Double(minimumAverageReadiness) else {
            // Застой при плохом сне/готовности — не повод срочно менять упражнения, причина в восстановлении.
            return nil
        }

        let deltaPercent = ((last.bestE1RMKg - first.bestE1RMKg) / first.bestE1RMKg) * 100.0
        guard deltaPercent <= growthThresholdPercent else {
            return nil
        }

        let daName = exercise.name.resolved(for: .da)
        let ruName = exercise.name.resolved(for: .ru)

        return BlockShiftRecommendation(
            exerciseID: exercise.id,
            exerciseName: exercise.name,
            stagnationWeeks: minimumWeeksRequired,
            e1RMDeltaPercent: (deltaPercent * 10.0).rounded() / 10.0,
            message: LocalizedCopy(
                da: "\(daName): e1RM har stået stille i \(minimumWeeksRequired) uger trods god restitution. Overvej at afslutte blokken med deload og skifte rep-område eller øvelsesvariant.",
                ru: "\(ruName): e1RM стоит на месте \(minimumWeeksRequired) недели подряд при хорошем восстановлении. Рекомендуется завершить блок разгрузкой и сменить диапазон повторов или вариант снаряда."
            )
        )
    }
}
