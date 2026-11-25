import Foundation
#if canImport(Testing)
import Testing
@testable import FitOnyCore

@Suite("Volume Calculator & 48h Recovery Window Tests")
struct VolumeAndRecoveryTests {
    @Test("Reverse pyramid progresses cleanly when stepped-down sets hit top reps")
    func reversePyramidProgression() {
        let exID = PumpetPonyCatalog.ExerciseIDs.inclineChestPress
        let scheme = PumpetPonyCatalog.moduleA.slots[0].scheme
        let eq = EquipmentProfile.machine(stepKg: 2.5)

        let completed = (0..<5).map { idx in
            let w = ProgressionEngine.targetWeightForSet(
                sessionTopWeightKg: 100.0,
                scheme: scheme,
                workingSetIndex: idx,
                equipment: eq
            )
            let r = scheme.repRange(forWorkingSetIndex: idx).max
            return CompletedSetRecord(exerciseID: exID, setIndex: idx, isWarmup: false, weightKg: w, completedReps: r, rir: 1)
        }

        let decision = ProgressionEngine.evaluateNextSession(
            currentLoad: ExerciseLoadState(exerciseID: exID, baselineWorkingWeightKg: 100.0),
            completedWorkingSets: completed,
            scheme: scheme,
            targetRIR: 1,
            equipment: eq
        )
        #expect(decision.didProgressWeight)
        #expect(decision.nextBaselineWeightKg == 102.5)
    }

    @Test("Volume calculator excludes warmups, halves drop steps, and computes Push/Pull balance")
    func weeklyFractionalVolume() {
        let inclineID = PumpetPonyCatalog.ExerciseIDs.inclineChestPress
        let rowID = PumpetPonyCatalog.ExerciseIDs.chestSupportedRow

        let sets: [CompletedSetRecord] = [
            CompletedSetRecord(exerciseID: inclineID, setIndex: 0, isWarmup: true, weightKg: 50, completedReps: 12, rir: 5),
            CompletedSetRecord(exerciseID: inclineID, setIndex: 1, isWarmup: false, weightKg: 90, completedReps: 8, rir: 1),
            CompletedSetRecord(exerciseID: inclineID, setIndex: 2, isWarmup: false, isDropStep: true, weightKg: 70, completedReps: 10, rir: 0),
            CompletedSetRecord(exerciseID: rowID, setIndex: 0, isWarmup: false, weightKg: 85, completedReps: 8, rir: 1),
            CompletedSetRecord(exerciseID: rowID, setIndex: 1, isWarmup: false, weightKg: 85, completedReps: 8, rir: 1)
        ]

        let report = VolumeCalculator.calculateWeeklyReport(completedSets: sets)
        #expect(report.summariesByMuscle[.chest]?.effectiveWeeklySets == 1.5)
        #expect(report.summariesByMuscle[.triceps]?.effectiveWeeklySets == 0.75)
        #expect(report.summariesByMuscle[.upperBack]?.effectiveWeeklySets == 2.0)
        #expect(!report.pushPullBalance.isPushOverloaded)
    }

    @Test("Yesterday arm workout swaps Biceps to Lateral Raises in Module B without blocking Back day")
    func moduleBBicepsSwap() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let yesterday = now.addingTimeInterval(-22 * 3600)

        let armSets = (0..<4).map { idx in
            CompletedSetRecord(
                exerciseID: PumpetPonyCatalog.ExerciseIDs.preacherCurl,
                setIndex: idx,
                isWarmup: false,
                weightKg: 35,
                completedReps: 9,
                rir: 0,
                completedAt: yesterday
            )
        }

        let eval = RecoveryWindowTracker.evaluateModule(
            PumpetPonyCatalog.moduleB,
            recentSets: armSets,
            referenceDate: now,
            profile: .natural
        )

        #expect(eval.isReadyForPrimaryWork)
        let lastSlotAdvice = eval.slotAdvices[4]
        #expect(lastSlotAdvice.kind == .swapExercise)
        #expect(lastSlotAdvice.recommendedExerciseID == PumpetPonyCatalog.ExerciseIDs.seatedDumbbellLateralRaise)
    }

    @Test("Training chest 24h ago flags Module A conflict and suggests rested alternative module")
    func moduleConflictSwapSuggestion() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let yesterday = now.addingTimeInterval(-24 * 3600)

        let chestSets = (0..<4).map { idx in
            CompletedSetRecord(
                exerciseID: PumpetPonyCatalog.ExerciseIDs.horizontalChestPress,
                setIndex: idx,
                isWarmup: false,
                weightKg: 80,
                completedReps: 9,
                rir: 1,
                completedAt: yesterday
            )
        }

        let eval = RecoveryWindowTracker.evaluateModule(
            PumpetPonyCatalog.moduleA,
            recentSets: chestSets,
            referenceDate: now,
            profile: .natural
        )

        #expect(!eval.isReadyForPrimaryWork)
        #expect(eval.conflictingPrimaryMuscles.contains(.chest))
        #expect(eval.suggestedAlternativeModuleCode == "B")
    }
}
#endif
