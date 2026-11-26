import Foundation

public struct MacrocyclePolicy: Codable, Sendable, Equatable {
    public var phase: MacrocyclePhase
    public var volumeMultiplier: Double
    public var defaultMesocycleWeeks: Int?
    public var requiredQualifyingSessionsToProgress: Int?
    public var compoundRestBonusSeconds: Int

    public init(
        phase: MacrocyclePhase,
        volumeMultiplier: Double,
        defaultMesocycleWeeks: Int?,
        requiredQualifyingSessionsToProgress: Int?,
        compoundRestBonusSeconds: Int
    ) {
        self.phase = phase
        self.volumeMultiplier = volumeMultiplier
        self.defaultMesocycleWeeks = defaultMesocycleWeeks
        self.requiredQualifyingSessionsToProgress = requiredQualifyingSessionsToProgress
        self.compoundRestBonusSeconds = compoundRestBonusSeconds
    }
}

public struct PrescribedSlot: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var exerciseID: UUID
    public var pairedExerciseID: UUID?
    public var scheme: SetScheme
    public var workingSetCount: Int
    public var repRangesBySet: [RepRange]
    public var targetRIR: Int
    public var weightScaleFactor: Double
    public var minRestSeconds: Int
    public var maxRestSeconds: Int
    public var warmup: WarmupPrescription
    public var tempo: TempoPrescription
    public var slotNote: BilingualText?

    public init(
        id: UUID,
        exerciseID: UUID,
        pairedExerciseID: UUID? = nil,
        scheme: SetScheme,
        workingSetCount: Int,
        repRangesBySet: [RepRange],
        targetRIR: Int,
        weightScaleFactor: Double,
        minRestSeconds: Int,
        maxRestSeconds: Int,
        warmup: WarmupPrescription,
        tempo: TempoPrescription = .controlledHypertrophy,
        slotNote: BilingualText? = nil
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.pairedExerciseID = pairedExerciseID
        self.scheme = scheme
        self.workingSetCount = workingSetCount
        self.repRangesBySet = repRangesBySet
        self.targetRIR = targetRIR
        self.weightScaleFactor = weightScaleFactor
        self.minRestSeconds = minRestSeconds
        self.maxRestSeconds = maxRestSeconds
        self.warmup = warmup
        self.tempo = tempo
        self.slotNote = slotNote
    }
}

public struct PrescribedWeekModule: Codable, Sendable, Equatable {
    public var weekNumber: Int
    public var totalWeeks: Int
    public var role: MesocycleWeekRole
    public var phase: MacrocyclePhase
    public var moduleCode: String
    public var moduleTitle: BilingualText
    public var slots: [PrescribedSlot]

    public init(
        weekNumber: Int,
        totalWeeks: Int,
        role: MesocycleWeekRole,
        phase: MacrocyclePhase,
        moduleCode: String,
        moduleTitle: BilingualText,
        slots: [PrescribedSlot]
    ) {
        self.weekNumber = weekNumber
        self.totalWeeks = totalWeeks
        self.role = role
        self.phase = phase
        self.moduleCode = moduleCode
        self.moduleTitle = moduleTitle
        self.slots = slots
    }
}

public enum PeriodizationEngine {
    public static func policy(for phase: MacrocyclePhase) -> MacrocyclePolicy {
        switch phase {
        case .hypertrophy:
            return MacrocyclePolicy(
                phase: .hypertrophy,
                volumeMultiplier: 1.0,
                defaultMesocycleWeeks: 6,
                requiredQualifyingSessionsToProgress: 1,
                compoundRestBonusSeconds: 0
            )
        case .cut:
            return MacrocyclePolicy(
                phase: .cut,
                volumeMultiplier: 0.75,
                defaultMesocycleWeeks: 5,
                requiredQualifyingSessionsToProgress: 2,
                compoundRestBonusSeconds: 0
            )
        case .strength:
            return MacrocyclePolicy(
                phase: .strength,
                volumeMultiplier: 0.85,
                defaultMesocycleWeeks: 5,
                requiredQualifyingSessionsToProgress: 1,
                compoundRestBonusSeconds: 60
            )
        case .maintenance:
            return MacrocyclePolicy(
                phase: .maintenance,
                volumeMultiplier: 0.65,
                defaultMesocycleWeeks: nil,
                requiredQualifyingSessionsToProgress: nil,
                compoundRestBonusSeconds: 0
            )
        }
    }

    public static func weekRole(
        weekNumber: Int,
        totalWeeks: Int,
        phase: MacrocyclePhase
    ) -> MesocycleWeekRole {
        let clampedTotal = max(4, min(6, totalWeeks))
        let clampedWeek = max(1, min(clampedTotal, weekNumber))

        if phase == .maintenance {
            return .acclimation
        }

        if clampedWeek == 1 {
            return .acclimation
        }

        if clampedWeek == clampedTotal {
            return .deload
        }

        if clampedTotal >= 6 && clampedWeek == clampedTotal - 1 {
            return .overreaching
        }

        return .accumulation
    }

    /// Строит точный план подходов, целевого RIR и отдыха для заданного модуля и недели мезоцикла.
    public static func prescribeModule(
        _ module: WorkoutModuleBlueprint,
        weekNumber: Int,
        totalWeeks: Int = 6,
        phase: MacrocyclePhase = .hypertrophy,
        exercisesByID: [UUID: ExerciseDefinition] = ProgramCatalog.builtIn.exercisesByID
    ) -> PrescribedWeekModule {
        let clampedTotal = max(4, min(6, totalWeeks))
        let clampedWeek = max(1, min(clampedTotal, weekNumber))
        let role = weekRole(weekNumber: clampedWeek, totalWeeks: clampedTotal, phase: phase)
        let macroPolicy = policy(for: phase)

        let prescribedSlots: [PrescribedSlot] = module.slots.map { slot in
            let isCompound = exercisesByID[slot.exerciseID]?.isCompound ?? false
            let baseSets = slot.scheme.workingSetCount

            let effectiveBaseSets: Int
            if role == .accumulation || role == .overreaching,
               phase == .hypertrophy,
               let accMax = slot.maxWorkingSetsInAccumulation {
                // В фазе накопления/пика поднимаем подходы (например, 3 -> 4 на 2-м касании спины).
                effectiveBaseSets = max(baseSets, accMax)
            } else {
                effectiveBaseSets = baseSets
            }

            let scaledByPhase = max(1, Int((Double(effectiveBaseSets) * macroPolicy.volumeMultiplier).rounded()))
            let finalWorkingSets: Int
            let targetRIR: Int

            switch role {
            case .acclimation:
                finalWorkingSets = phase == .cut || phase == .maintenance ? scaledByPhase : baseSets
                targetRIR = max(2, slot.targetRIR)

            case .accumulation:
                finalWorkingSets = phase == .hypertrophy ? effectiveBaseSets : scaledByPhase
                targetRIR = phase == .cut ? max(1, slot.targetRIR) : slot.targetRIR

            case .overreaching:
                finalWorkingSets = phase == .hypertrophy ? effectiveBaseSets : scaledByPhase
                targetRIR = isCompound ? max(1, slot.targetRIR) : 0

            case .deload:
                // Разгрузка: сохраняем 100% рабочего веса, режем количество рабочих подходов в 2 раза, RIR 3–4.
                finalWorkingSets = max(1, Int(ceil(Double(effectiveBaseSets) * 0.5)))
                targetRIR = 3
            }

            let repRanges = (0..<finalWorkingSets).map { idx in
                slot.scheme.repRange(forWorkingSetIndex: idx)
            }

            let restBonus = isCompound ? macroPolicy.compoundRestBonusSeconds : 0

            let pairedID: UUID? = if case let .superset(paired, _, _) = slot.scheme {
                paired
            } else {
                nil
            }

            return PrescribedSlot(
                id: slot.id,
                exerciseID: slot.exerciseID,
                pairedExerciseID: pairedID,
                scheme: slot.scheme,
                workingSetCount: finalWorkingSets,
                repRangesBySet: repRanges,
                targetRIR: targetRIR,
                weightScaleFactor: 1.0,
                minRestSeconds: slot.minRestSeconds + restBonus,
                maxRestSeconds: slot.maxRestSeconds + restBonus,
                warmup: slot.warmup,
                tempo: slot.tempo,
                slotNote: slot.slotNote
            )
        }

        return PrescribedWeekModule(
            weekNumber: clampedWeek,
            totalWeeks: clampedTotal,
            role: role,
            phase: phase,
            moduleCode: module.code,
            moduleTitle: module.title,
            slots: prescribedSlots
        )
    }
}
