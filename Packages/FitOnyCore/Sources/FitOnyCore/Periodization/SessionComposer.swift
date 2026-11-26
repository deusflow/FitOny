import Foundation

public struct ComposedExercisePlan: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var exerciseID: UUID
    public var pairedExerciseID: UUID?
    public var equipmentVariant: EquipmentVariant
    public var activeEquipment: EquipmentProfile
    public var warmupSets: [WarmupSetStep]
    public var workingSetWeightsKg: [Double]
    public var workingSetRepRanges: [RepRange]
    public var targetRIR: Int
    public var minRestSeconds: Int
    public var maxRestSeconds: Int
    public var tempo: TempoPrescription
    public var appliedAdaptation: SlotAdaptationKind
    public var slotNote: BilingualText?

    public init(
        id: UUID,
        exerciseID: UUID,
        pairedExerciseID: UUID?,
        equipmentVariant: EquipmentVariant,
        activeEquipment: EquipmentProfile,
        warmupSets: [WarmupSetStep],
        workingSetWeightsKg: [Double],
        workingSetRepRanges: [RepRange],
        targetRIR: Int,
        minRestSeconds: Int,
        maxRestSeconds: Int,
        tempo: TempoPrescription,
        appliedAdaptation: SlotAdaptationKind,
        slotNote: BilingualText?
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.pairedExerciseID = pairedExerciseID
        self.equipmentVariant = equipmentVariant
        self.activeEquipment = activeEquipment
        self.warmupSets = warmupSets
        self.workingSetWeightsKg = workingSetWeightsKg
        self.workingSetRepRanges = workingSetRepRanges
        self.targetRIR = targetRIR
        self.minRestSeconds = minRestSeconds
        self.maxRestSeconds = maxRestSeconds
        self.tempo = tempo
        self.appliedAdaptation = appliedAdaptation
        self.slotNote = slotNote
    }
}

public struct ComposedWorkoutSession: Codable, Sendable, Equatable {
    public var sessionID: UUID
    public var moduleCode: String
    public var moduleTitle: BilingualText
    public var weekNumber: Int
    public var weekRole: MesocycleWeekRole
    public var phase: MacrocyclePhase
    public var readinessEvaluation: ModuleReadinessEvaluation
    public var exercises: [ComposedExercisePlan]

    public init(
        sessionID: UUID = UUID(),
        moduleCode: String,
        moduleTitle: BilingualText,
        weekNumber: Int,
        weekRole: MesocycleWeekRole,
        phase: MacrocyclePhase,
        readinessEvaluation: ModuleReadinessEvaluation,
        exercises: [ComposedExercisePlan]
    ) {
        self.sessionID = sessionID
        self.moduleCode = moduleCode
        self.moduleTitle = moduleTitle
        self.weekNumber = weekNumber
        self.weekRole = weekRole
        self.phase = phase
        self.readinessEvaluation = readinessEvaluation
        self.exercises = exercises
    }
}

/// Единый дирижёр сборки сегодняшней тренировки для iPhone и Apple Watch.
/// Гарантирует правильный порядок: сначала умные замены по 48 ч, затем масштабирование недели (включая Deload),
/// затем подбор веса под конкретный вариант снаряда и расчёт разминки без дублей на разогретых мышцах.
public enum SessionComposer {
    public static func compose(
        module: WorkoutModuleBlueprint,
        program: ProgramTemplate,
        catalog: ProgramCatalog = .builtIn,
        weekNumber: Int,
        totalWeeks: Int = 6,
        phase: MacrocyclePhase = .hypertrophy,
        profile: PhysiologicalProfile = .natural,
        recentSets: [CompletedSetRecord] = [],
        weeklySets: [CompletedSetRecord] = [],
        plannedDirectMusclesNext24h: Set<MuscleGroup> = [],
        acceptedAdaptationSlotIDs: Set<UUID>? = nil,
        selectedVariantsBySlotID: [UUID: EquipmentVariant] = [:],
        loadStatesByKey: [ExerciseEquipmentKey: ExerciseLoadState] = [:],
        referenceDate: Date = .now
    ) -> ComposedWorkoutSession {
        let evaluation = RecoveryWindowTracker.evaluateModule(
            module,
            candidateModules: program.modules,
            recentSets: recentSets,
            weeklySets: weeklySets,
            plannedDirectMusclesNext24h: plannedDirectMusclesNext24h,
            referenceDate: referenceDate,
            profile: profile,
            exercisesByID: catalog.exercisesByID
        )

        // 1. Применяем принятые пользователем (или рекомендованные по умолчанию) замены/пропуски слотов ДО расчёта недели Deload
        var adaptedSlots: [ModuleExerciseSlot] = []
        var kindBySlotID: [UUID: SlotAdaptationKind] = [:]

        for (slot, advice) in zip(module.slots, evaluation.slotAdvices) {
            let shouldApplyAdvice = acceptedAdaptationSlotIDs.map { $0.contains(slot.id) } ?? true

            if !shouldApplyAdvice {
                if case .optionalBonusIfMuscleRested = slot.condition {
                    continue
                }
                adaptedSlots.append(slot)
                kindBySlotID[slot.id] = .keepAsPlanned
                continue
            }

            switch advice.kind {
            case .skipOptionalOrGated:
                continue
            case .keepAsPlanned, .includeOptionalBonus:
                adaptedSlots.append(slot)
                kindBySlotID[slot.id] = advice.kind
            case .swapExercise, .suggestHeavyAlternative:
                let replacedSlot = ModuleExerciseSlot(
                    id: slot.id,
                    exerciseID: advice.recommendedExerciseID,
                    scheme: advice.recommendedScheme,
                    maxWorkingSetsInAccumulation: nil,
                    warmup: advice.recommendedWarmup,
                    targetRIR: advice.recommendedRIR,
                    minRestSeconds: advice.recommendedRestSeconds,
                    maxRestSeconds: advice.recommendedRestSeconds,
                    tempo: slot.tempo,
                    condition: .required,
                    slotNote: slot.slotNote
                )
                adaptedSlots.append(replacedSlot)
                kindBySlotID[slot.id] = advice.kind
            }
        }

        let adaptedModule = WorkoutModuleBlueprint(
            id: module.id,
            code: module.code,
            title: module.title,
            slots: adaptedSlots
        )

        // 2. Накладываем правила текущей недели мезоцикла (включая резание подходов в 2 раза на неделе Deload)
        let prescribed = PeriodizationEngine.prescribeModule(
            adaptedModule,
            weekNumber: weekNumber,
            totalWeeks: totalWeeks,
            phase: phase,
            exercisesByID: catalog.exercisesByID
        )

        // 3. Строим разминку (пропуская уже разогретые в этой сессии мышцы) и целевые веса по выбранному снаряду
        var warmedPrimaryMuscles: Set<MuscleGroup> = []
        var composedExercises: [ComposedExercisePlan] = []

        for pSlot in prescribed.slots {
            guard let exercise = catalog.exercisesByID[pSlot.exerciseID] else { continue }
            let variant = selectedVariantsBySlotID[pSlot.id] ?? .primary
            let equipment = exercise.equipment(for: variant)

            let key = ExerciseEquipmentKey(exerciseID: pSlot.exerciseID, variant: variant)
            let sessionTopWeight = (loadStatesByKey[key]?.sessionTargetWeightKg ?? 0.0) * pSlot.weightScaleFactor

            let primaryMusclesOfEx = Set(exercise.muscleContributions.filter { $0.value >= 0.99 }.map(\.key))
            let alreadyWarmed = !primaryMusclesOfEx.isEmpty && primaryMusclesOfEx.isSubset(of: warmedPrimaryMuscles)

            let warmups = sessionTopWeight > 0
                ? WarmupGenerator.generate(
                    firstWorkingWeightKg: sessionTopWeight,
                    equipment: equipment,
                    prescription: pSlot.warmup,
                    alreadyTrainedPrimaryMuscleInSession: alreadyWarmed
                )
                : []

            warmedPrimaryMuscles.formUnion(primaryMusclesOfEx)

            let setWeights = (0..<pSlot.workingSetCount).map { idx in
                sessionTopWeight > 0
                    ? ProgressionEngine.targetWeightForSet(
                        sessionTopWeightKg: sessionTopWeight,
                        scheme: pSlot.scheme,
                        workingSetIndex: idx,
                        equipment: equipment
                    )
                    : 0.0
            }

            composedExercises.append(
                ComposedExercisePlan(
                    id: pSlot.id,
                    exerciseID: pSlot.exerciseID,
                    pairedExerciseID: pSlot.pairedExerciseID,
                    equipmentVariant: variant,
                    activeEquipment: equipment,
                    warmupSets: warmups,
                    workingSetWeightsKg: setWeights,
                    workingSetRepRanges: pSlot.repRangesBySet,
                    targetRIR: pSlot.targetRIR,
                    minRestSeconds: pSlot.minRestSeconds,
                    maxRestSeconds: pSlot.maxRestSeconds,
                    tempo: pSlot.tempo,
                    appliedAdaptation: kindBySlotID[pSlot.id] ?? .keepAsPlanned,
                    slotNote: pSlot.slotNote
                )
            )
        }

        return ComposedWorkoutSession(
            moduleCode: module.code,
            moduleTitle: module.title,
            weekNumber: prescribed.weekNumber,
            weekRole: prescribed.role,
            phase: prescribed.phase,
            readinessEvaluation: evaluation,
            exercises: composedExercises
        )
    }
}
