import Foundation
#if canImport(Testing)
import Testing
@testable import FitOnyCore

@Suite("SessionComposer, Equipment Variants & Custom Programs Tests")
struct SessionComposerTests {
    @Test("Deload week properly halves sets even on a 48h-swapped exercise")
    func deloadPlusFatigueSwap() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let armSessionID = UUID()
        let yesterdayArmSets = (0..<4).map { idx in
            CompletedSetRecord(
                sessionID: armSessionID,
                exerciseID: PumpetPonyCatalog.ExerciseIDs.preacherCurl,
                setIndex: idx,
                isWarmup: false,
                weightKg: 35,
                completedReps: 9,
                rir: 0,
                completedAt: now.addingTimeInterval(-20 * 3600)
            )
        }

        let composed = SessionComposer.compose(
            module: PumpetPonyCatalog.moduleB,
            program: PumpetPonyCatalog.programTemplate,
            weekNumber: 6,
            totalWeeks: 6,
            phase: .hypertrophy,
            recentSets: yesterdayArmSets,
            referenceDate: now
        )

        #expect(composed.weekRole == .deload)
        let lastPlan = composed.exercises.last!
        #expect(lastPlan.appliedAdaptation == .swapExercise)
        #expect(lastPlan.exerciseID == PumpetPonyCatalog.ExerciseIDs.seatedDumbbellLateralRaise)
        // Заменённое упражнение (4 сета в норме) в неделю Deload обязано урезаться до 2 сетов с RIR 3
        #expect(lastPlan.workingSetRepRanges.count == 2)
        #expect(lastPlan.targetRIR == 3)
    }

    @Test("Primary machine weight and alternative dumbbell weight progress independently")
    func independentEquipmentVariants() {
        let exID = PumpetPonyCatalog.ExerciseIDs.horizontalChestPress
        let machineState = ExerciseLoadState(exerciseID: exID, equipmentVariant: .primary, baselineWorkingWeightKg: 90)
        let dbState = ExerciseLoadState(exerciseID: exID, equipmentVariant: .alternative, baselineWorkingWeightKg: 32)

        let dbSets = (0..<4).map { idx in
            CompletedSetRecord(
                exerciseID: exID,
                equipmentVariant: .alternative,
                setIndex: idx,
                isWarmup: false,
                weightKg: 32,
                completedReps: 10,
                rir: 1
            )
        }

        let dbProg = ProgressionEngine.evaluateNextSession(
            currentLoad: dbState,
            completedWorkingSets: dbSets,
            scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 10)),
            targetRIR: 1,
            equipment: .dumbbellRack()
        )
        #expect(dbProg.didProgressWeight)
        #expect(dbProg.nextBaselineWeightKg == 34.0)

        let machineProg = ProgressionEngine.evaluateNextSession(
            currentLoad: machineState,
            completedWorkingSets: dbSets,
            scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 10)),
            targetRIR: 1,
            equipment: .machine(stepKg: 2.5)
        )
        #expect(!machineProg.didProgressWeight)
        #expect(machineProg.nextBaselineWeightKg == 90.0)
    }

    @Test("Workout crossing midnight stays grouped as one session via sessionID")
    func midnightSessionContinuity() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let beforeMidnight = cal.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: 23, minute: 50))!
        let afterMidnight = cal.date(from: DateComponents(year: 2026, month: 11, day: 26, hour: 0, minute: 15))!
        let nextAfternoon = cal.date(from: DateComponents(year: 2026, month: 11, day: 26, hour: 16, minute: 0))!

        let lateSessionID = UUID()
        let sets = [
            CompletedSetRecord(sessionID: lateSessionID, exerciseID: PumpetPonyCatalog.ExerciseIDs.horizontalChestPress, setIndex: 0, isWarmup: false, weightKg: 80, completedReps: 9, rir: 1, completedAt: beforeMidnight),
            CompletedSetRecord(sessionID: lateSessionID, exerciseID: PumpetPonyCatalog.ExerciseIDs.horizontalChestPress, setIndex: 1, isWarmup: false, weightKg: 80, completedReps: 9, rir: 1, completedAt: afterMidnight)
        ]

        let statuses = RecoveryWindowTracker.recoveryStatuses(recentSets: sets, referenceDate: nextAfternoon)
        #expect(statuses[.chest]?.isRecoveringFromDirectWork == true)
    }
}
#endif
