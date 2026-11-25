import Foundation
#if canImport(Testing)
import Testing
@testable import FitOnyCore

@Suite("Periodization & Plateau Tests")
struct PeriodizationTests {
    @Test("6-week Pumpet Pony mesocycle progresses sets and halves volume in deload keeping 100% weight")
    func sixWeekMesocycle() {
        let week1 = PeriodizationEngine.prescribeModule(PumpetPonyCatalog.moduleD, weekNumber: 1, totalWeeks: 6, phase: .hypertrophy)
        let week3 = PeriodizationEngine.prescribeModule(PumpetPonyCatalog.moduleD, weekNumber: 3, totalWeeks: 6, phase: .hypertrophy)
        let week5 = PeriodizationEngine.prescribeModule(PumpetPonyCatalog.moduleD, weekNumber: 5, totalWeeks: 6, phase: .hypertrophy)
        let week6 = PeriodizationEngine.prescribeModule(PumpetPonyCatalog.moduleD, weekNumber: 6, totalWeeks: 6, phase: .hypertrophy)

        #expect(week1.role == .acclimation)
        #expect(week1.slots.allSatisfy { $0.targetRIR >= 2 })

        // 2-е касание спины (индекс 5 в Модуле D): Неделя 1 -> 3 сета, Недели 3 и 5 -> 4 сета, Неделя 6 (Deload) -> 2 сета
        #expect(week1.slots[5].workingSetCount == 3)
        #expect(week3.slots[5].workingSetCount == 4)
        #expect(week5.role == .overreaching)
        #expect(week5.slots[5].workingSetCount == 4)

        #expect(week6.role == .deload)
        #expect(week6.slots[0].workingSetCount == 2) // 4 -> 2
        #expect(week6.slots[5].workingSetCount == 2) // 4 -> 2
        #expect(week6.slots.allSatisfy { $0.weightScaleFactor == 1.0 && $0.targetRIR == 3 })
    }

    @Test("Plateau detector triggers only when readiness is normal and e1RM stalls for 3 weeks")
    func plateauDetection() {
        let inclinePress = PumpetPonyCatalog.exerciseByID[PumpetPonyCatalog.ExerciseIDs.inclineChestPress]!

        let stalledGoodSleep = [
            WeeklyExercisePerformance(weekNumber: 2, bestE1RMKg: 115.0, averageReadinessScore: 76),
            WeeklyExercisePerformance(weekNumber: 3, bestE1RMKg: 115.4, averageReadinessScore: 81),
            WeeklyExercisePerformance(weekNumber: 4, bestE1RMKg: 115.2, averageReadinessScore: 74)
        ]
        let recommendation = PlateauDetector.evaluate(exercise: inclinePress, weeklyHistory: stalledGoodSleep)
        #expect(recommendation != nil)

        let stalledBadSleep = [
            WeeklyExercisePerformance(weekNumber: 2, bestE1RMKg: 115.0, averageReadinessScore: 48),
            WeeklyExercisePerformance(weekNumber: 3, bestE1RMKg: 114.0, averageReadinessScore: 51),
            WeeklyExercisePerformance(weekNumber: 4, bestE1RMKg: 113.5, averageReadinessScore: 50)
        ]
        let suppressed = PlateauDetector.evaluate(exercise: inclinePress, weeklyHistory: stalledBadSleep)
        #expect(suppressed == nil)
    }
}
#endif
