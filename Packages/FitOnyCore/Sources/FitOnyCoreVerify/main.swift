import Foundation
import FitOnyCore

@main
struct FitOnyCoreVerify {
    static func main() {
        let program = PumpetPonyCatalog.programTemplate
        precondition(program.name.resolved(for: .da) == "Pumpet Pony")
        precondition(program.name.resolved(for: .ru) == "Накаченная пони")
        precondition(program.modules.count == 5, "Ожидалось 5 модулей A–E")

        for module in program.modules {
            for slot in module.slots {
                precondition(
                    PumpetPonyCatalog.exerciseByID[slot.exerciseID] != nil,
                    "Не найдено упражнение в каталоге для модуля \(module.code)"
                )
            }
        }

        // Проверка подсчёта недельного дробного объёма для бицепса и трицепса (без опциональной добавки в A и без дня E)
        let baseModules = [PumpetPonyCatalog.moduleA, PumpetPonyCatalog.moduleB, PumpetPonyCatalog.moduleC, PumpetPonyCatalog.moduleD]
        var fractionalSets: [MuscleGroup: Double] = [:]
        for module in baseModules {
            for slot in module.slots {
                if case .optionalBonusIfMuscleRested = slot.condition { continue }
                guard let ex = PumpetPonyCatalog.exerciseByID[slot.exerciseID] else { continue }
                let sets = Double(slot.scheme.workingSetCount)
                for (muscle, coeff) in ex.muscleContributions {
                    fractionalSets[muscle, default: 0] += sets * coeff
                }
            }
        }

        let bicepsTotal = fractionalSets[.biceps, default: 0]
        let tricepsTotal = fractionalSets[.triceps, default: 0]
        precondition(bicepsTotal >= 14.0, "Ожидался высокий объём бицепса по приоритету 1")
        precondition(tricepsTotal >= 10.5 && tricepsTotal <= 14.0, "Ожидался сбалансированный объём трицепса 11–13 подходов")

        // Проверка разминки: перед первым базовым жимом 90 кг -> 2 сета, на втором упражнении на грудь -> 0 сетов
        let inclineWarmup = WarmupGenerator.generate(
            firstWorkingWeightKg: 90,
            equipment: .machine(stepKg: 2.5),
            prescription: .standardDoubleWarmup,
            alreadyTrainedPrimaryMuscleInSession: false
        )
        precondition(inclineWarmup.count == 2 && inclineWarmup[0].weightKg == 45 && inclineWarmup[1].weightKg == 67.5)

        let flatWarmup = WarmupGenerator.generate(
            firstWorkingWeightKg: 80,
            equipment: .machine(stepKg: 2.5),
            prescription: .none,
            alreadyTrainedPrimaryMuscleInSession: true
        )
        precondition(flatWarmup.isEmpty)

        // Проверка Double Progression (4x8-10 @ 90 кг -> +2.5 кг)
        let flatExID = PumpetPonyCatalog.ExerciseIDs.horizontalChestPress
        let closedSets = (0..<4).map { idx in
            CompletedSetRecord(exerciseID: flatExID, setIndex: idx, isWarmup: false, weightKg: 90, completedReps: 10, rir: 1)
        }
        let progression = ProgressionEngine.evaluateNextSession(
            currentLoad: ExerciseLoadState(exerciseID: flatExID, baselineWorkingWeightKg: 90),
            completedWorkingSets: closedSets,
            scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 10)),
            targetRIR: 1,
            equipment: .machine(stepKg: 2.5)
        )
        precondition(progression.didProgressWeight && progression.nextBaselineWeightKg == 92.5)

        // Проверка внутрисессионной авторегуляции (сделали 5 вместо 8 -> снижение на ~10%, но базовый вес не портится)
        let badSet = CompletedSetRecord(exerciseID: flatExID, setIndex: 0, isWarmup: false, weightKg: 90, completedReps: 5, rir: 0)
        let adjustment = AutoregulationEngine.evaluateAfterSet(
            completedSet: badSet,
            plannedRange: RepRange(min: 8, max: 10),
            targetRIR: 1,
            equipment: .machine(stepKg: 2.5)
        )
        precondition(adjustment.wasReduced && adjustment.adjustedRemainingWeightKg == 80.0)

        // Проверка e1RM и калькулятора блинов (87.5 кг: с 25-ками -> [25, 5, 2.5, 1.25], без 25-ок -> [20, 10, 2.5, 1.25])
        let e1rm = E1RMCalculator.estimate(weightKg: 90, reps: 8, rir: 1) ?? 0
        precondition(e1rm > 115 && e1rm < 120)
        let platesWith25 = PlateCalculator.platesPerSide(totalWeightKg: 87.5)
        precondition(platesWith25.platesPerSideKg == [25, 5, 2.5, 1.25])
        let platesMax20 = PlateCalculator.platesPerSide(totalWeightKg: 87.5, availablePlatesKg: [20, 15, 10, 5, 2.5, 1.25])
        precondition(platesMax20.platesPerSideKg == [20, 10, 2.5, 1.25])

        print("FitOnyCoreVerify OK: программа «\(program.name.resolved(for: .da)) / \(program.name.resolved(for: .ru))» (5 модулей, \(PumpetPonyCatalog.exercises.count) упр.), трицепс=\(tricepsTotal), бицепс=\(bicepsTotal) дробн. сетов; движок разминки, прогрессии, авторегуляции и блинов проверен.")
    }
}
