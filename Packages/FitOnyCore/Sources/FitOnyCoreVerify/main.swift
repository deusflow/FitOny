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

        // День 3: Симуляция 6-недельного мезоцикла Hypertrophy для Модуля D и Модуля A
        let dWeek1 = PeriodizationEngine.prescribeModule(PumpetPonyCatalog.moduleD, weekNumber: 1, totalWeeks: 6, phase: .hypertrophy)
        let dWeek3 = PeriodizationEngine.prescribeModule(PumpetPonyCatalog.moduleD, weekNumber: 3, totalWeeks: 6, phase: .hypertrophy)
        let dWeek6 = PeriodizationEngine.prescribeModule(PumpetPonyCatalog.moduleD, weekNumber: 6, totalWeeks: 6, phase: .hypertrophy)
        precondition(dWeek1.role == .acclimation && dWeek1.slots[5].workingSetCount == 3 && dWeek1.slots[5].targetRIR == 2)
        precondition(dWeek3.role == .accumulation && dWeek3.slots[5].workingSetCount == 4 && dWeek3.slots[5].targetRIR == 1)
        precondition(dWeek6.role == .deload && dWeek6.slots[0].workingSetCount == 2 && dWeek6.slots[0].weightScaleFactor == 1.0 && dWeek6.slots[0].targetRIR == 3)

        let aWeek6 = PeriodizationEngine.prescribeModule(PumpetPonyCatalog.moduleA, weekNumber: 6, totalWeeks: 6, phase: .hypertrophy)
        precondition(aWeek6.slots[0].workingSetCount == 3) // 5 подходов обратной пирамиды -> 3 подхода в Deload

        // Проверка детектора плато
        let inclineEx = PumpetPonyCatalog.exerciseByID[PumpetPonyCatalog.ExerciseIDs.inclineChestPress]!
        let plateau = PlateauDetector.evaluate(
            exercise: inclineEx,
            weeklyHistory: [
                WeeklyExercisePerformance(weekNumber: 2, bestE1RMKg: 115.0, averageReadinessScore: 76),
                WeeklyExercisePerformance(weekNumber: 3, bestE1RMKg: 115.4, averageReadinessScore: 80),
                WeeklyExercisePerformance(weekNumber: 4, bestE1RMKg: 115.1, averageReadinessScore: 74)
            ]
        )
        precondition(plateau != nil)

        // Аудит обратной пирамиды: ступенчатые веса 100%, 90%, 82.5% должны корректно давать прогрессию +2.5 кг
        let pyramidScheme = PumpetPonyCatalog.moduleA.slots[0].scheme
        let pyramidCompleted = (0..<5).map { idx in
            let w = ProgressionEngine.targetWeightForSet(
                sessionTopWeightKg: 100.0,
                scheme: pyramidScheme,
                workingSetIndex: idx,
                equipment: .machine(stepKg: 2.5)
            )
            return CompletedSetRecord(
                exerciseID: PumpetPonyCatalog.ExerciseIDs.inclineChestPress,
                setIndex: idx,
                isWarmup: false,
                weightKg: w,
                completedReps: pyramidScheme.repRange(forWorkingSetIndex: idx).max,
                rir: 1
            )
        }
        let pyramidDecision = ProgressionEngine.evaluateNextSession(
            currentLoad: ExerciseLoadState(exerciseID: PumpetPonyCatalog.ExerciseIDs.inclineChestPress, baselineWorkingWeightKg: 100.0),
            completedWorkingSets: pyramidCompleted,
            scheme: pyramidScheme,
            targetRIR: 1,
            equipment: .machine(stepKg: 2.5)
        )
        precondition(pyramidDecision.didProgressWeight && pyramidDecision.nextBaselineWeightKg == 102.5)

        // День 4: VolumeCalculator (разминка=0, дроп-сет=0.5x, баланс Push/Pull) и RecoveryWindowTracker (правило 48 ч и умные замены)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let twentyHoursAgo = now.addingTimeInterval(-20 * 3600)
        let yesterdayArmSets = (0..<4).map { idx in
            CompletedSetRecord(
                exerciseID: PumpetPonyCatalog.ExerciseIDs.preacherCurl,
                setIndex: idx,
                isWarmup: false,
                weightKg: 35,
                completedReps: 9,
                rir: 0,
                completedAt: twentyHoursAgo
            )
        }

        // Сценарий: вчера качали руки, сегодня открываем Модуль B (Спина + Задняя дельта + Бицепс)
        let modBEval = RecoveryWindowTracker.evaluateModule(
            PumpetPonyCatalog.moduleB,
            recentSets: yesterdayArmSets,
            referenceDate: now,
            profile: .natural
        )
        precondition(modBEval.isReadyForPrimaryWork, "Спина свежая — Модуль B не должен блокироваться из-за вчерашних рук")
        precondition(
            modBEval.slotAdvices[4].kind == .swapExercise &&
            modBEval.slotAdvices[4].recommendedExerciseID == PumpetPonyCatalog.ExerciseIDs.seatedDumbbellLateralRaise,
            "5-й слот Модуля B (бицепс 45°) должен автоматически предлагать замену на махи гантелями сидя"
        )

        // Сценарий: в Модуле D прошло >10 дней без Гакк-приседа -> предложение тяжёлого варианта на квадрицепс
        let modDEval = RecoveryWindowTracker.evaluateModule(
            PumpetPonyCatalog.moduleD,
            recentSets: yesterdayArmSets,
            referenceDate: now,
            profile: .natural
        )
        precondition(
            modDEval.slotAdvices[3].kind == .suggestHeavyAlternative &&
            modDEval.slotAdvices[3].recommendedExerciseID == PumpetPonyCatalog.ExerciseIDs.hackSquatOrLegPress,
            "4-й слот Модуля D должен предложить тяжёлый Гакк-присед / жим ногами раз в 10–14 дней"
        )

        let volReport = VolumeCalculator.calculateWeeklyReport(completedSets: pyramidCompleted + yesterdayArmSets)
        precondition(volReport.orderedSummaries.count == 14)
        precondition(volReport.summariesByMuscle[.chest]?.effectiveWeeklySets == 5.0)
        precondition(volReport.summariesByMuscle[.biceps]?.effectiveWeeklySets == 4.0)

        print("FitOnyCoreVerify OK: «\(program.name.resolved(for: .da)) / \(program.name.resolved(for: .ru))» проверена; 6-нед. мезоцикл, обратная пирамида, VolumeCalculator (14 мышц) и RecoveryWindowTracker (48ч + замены A–E) работают без ошибок.")
    }
}
