import Foundation
#if canImport(Testing)
import Testing
@testable import FitOnyCore

@Suite("Pumpet Pony & Workout Engine Tests")
struct WorkoutEngineTests {
    @Test("Pumpet Pony program has 5 modules and valid bilingual exercise links")
    func pumpetPonyIntegrity() {
        let program = PumpetPonyCatalog.programTemplate
        #expect(program.name.resolved(for: .da) == "Pumpet Pony")
        #expect(program.name.resolved(for: .ru) == "Накаченная пони")
        #expect(program.modules.count == 5)
        for module in program.modules {
            for slot in module.slots {
                #expect(PumpetPonyCatalog.exerciseByID[slot.exerciseID] != nil)
            }
        }
    }

    @Test("Warmup pyramid rounds to machine step and skips already warmed muscle")
    func warmupGeneration() {
        let steps = WarmupGenerator.generate(
            firstWorkingWeightKg: 90,
            equipment: .machine(stepKg: 2.5),
            prescription: .standardDoubleWarmup
        )
        #expect(steps.map(\.weightKg) == [45.0, 67.5])
        #expect(steps.map(\.targetReps) == [12, 8])

        let skipped = WarmupGenerator.generate(
            firstWorkingWeightKg: 80,
            equipment: .machine(stepKg: 2.5),
            prescription: .standardDoubleWarmup,
            alreadyTrainedPrimaryMuscleInSession: true
        )
        #expect(skipped.isEmpty)
    }

    @Test("Double progression increments barbell/machine by 2.5 and dumbbells along rack")
    func doubleProgression() {
        let exID = PumpetPonyCatalog.ExerciseIDs.incline45DumbbellCurl
        let sets = (0..<4).map {
            CompletedSetRecord(exerciseID: exID, setIndex: $0, isWarmup: false, weightKg: 14, completedReps: 12, rir: 0)
        }
        let decision = ProgressionEngine.evaluateNextSession(
            currentLoad: ExerciseLoadState(exerciseID: exID, baselineWorkingWeightKg: 14),
            completedWorkingSets: sets,
            scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 12)),
            targetRIR: 0,
            equipment: .dumbbellRack()
        )
        #expect(decision.didProgressWeight)
        #expect(decision.nextBaselineWeightKg == 16.0)
    }

    @Test("Intra-session autoregulation reduces weight on shortfall without changing baseline")
    func intraSessionDrop() {
        let set = CompletedSetRecord(
            exerciseID: PumpetPonyCatalog.ExerciseIDs.horizontalChestPress,
            setIndex: 0,
            isWarmup: false,
            weightKg: 90,
            completedReps: 5,
            rir: 0
        )
        let adj = AutoregulationEngine.evaluateAfterSet(
            completedSet: set,
            plannedRange: RepRange(min: 8, max: 10),
            targetRIR: 1,
            equipment: .machine(stepKg: 2.5)
        )
        #expect(adj.wasReduced)
        #expect(adj.adjustedRemainingWeightKg == 80.0)
    }

    @Test("Plate calculator returns exact metric plates per side")
    func platesBreakdown() {
        let loadoutWith25 = PlateCalculator.platesPerSide(totalWeightKg: 87.5)
        #expect(loadoutWith25.platesPerSideKg == [25, 5, 2.5, 1.25])

        let loadoutMax20 = PlateCalculator.platesPerSide(
            totalWeightKg: 87.5,
            availablePlatesKg: [20, 15, 10, 5, 2.5, 1.25]
        )
        #expect(loadoutMax20.platesPerSideKg == [20, 10, 2.5, 1.25])
    }
}
#endif
