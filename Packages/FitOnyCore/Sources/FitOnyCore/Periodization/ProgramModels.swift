import Foundation

public enum MacrocyclePhase: String, Codable, Sendable, CaseIterable {
    case hypertrophy
    case cut
    case strength
    case maintenance

    public var localizedName: LocalizedCopy {
        switch self {
        case .hypertrophy: LocalizedCopy(da: "Muskelopbygning", ru: "Набор массы")
        case .cut: LocalizedCopy(da: "Cut / Fedttab", ru: "Сушка / удержание")
        case .strength: LocalizedCopy(da: "Styrke", ru: "Силовой пик")
        case .maintenance: LocalizedCopy(da: "Vedligeholdelse", ru: "Поддержание")
        }
    }
}

public enum MesocycleWeekRole: String, Codable, Sendable, Equatable {
    case acclimation    // Неделя 1: MEV, RIR 2
    case accumulation   // Недели 2–4: MAV, RIR 0–1
    case overreaching   // Опциональная пиковая неделя перед разгрузкой
    case deload         // Разгрузка: 100% веса, 50% рабочих подходов, RIR 3–4

    public var localizedName: LocalizedCopy {
        switch self {
        case .acclimation: LocalizedCopy(da: "Tilvænning", ru: "Втягивающая")
        case .accumulation: LocalizedCopy(da: "Opbygning", ru: "Накопление")
        case .overreaching: LocalizedCopy(da: "Topbelastning", ru: "Пиковая перегрузка")
        case .deload: LocalizedCopy(da: "Deload (Let uge)", ru: "Разгрузка (Deload)")
        }
    }
}

public enum SlotCondition: Codable, Sendable, Equatable {
    case required
    case optionalBonusIfMuscleRested(muscle: MuscleGroup, minHours: Double, reason: LocalizedCopy)
    case gatedByMuscleRecovery(muscle: MuscleGroup, minHours: Double, reason: LocalizedCopy)
    case swapIfMuscleFatigued(
        muscle: MuscleGroup,
        withinHours: Double,
        swapExerciseID: UUID,
        swapScheme: SetScheme,
        swapRestSeconds: Int,
        swapRIR: Int,
        reason: LocalizedCopy
    )
    case biWeeklyChoice(
        suggestedIntervalDays: Int,
        alternativeExerciseID: UUID,
        alternativeScheme: SetScheme,
        alternativeWarmup: WarmupPrescription,
        alternativeRestSeconds: Int,
        alternativeRIR: Int,
        reason: LocalizedCopy
    )
    case catchUpIfMuscleUnderVolume(muscle: MuscleGroup, reason: LocalizedCopy)
}

public struct ModuleExerciseSlot: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var exerciseID: UUID
    public var scheme: SetScheme
    public var maxWorkingSetsInAccumulation: Int?
    public var warmup: WarmupPrescription
    public var targetRIR: Int
    public var minRestSeconds: Int
    public var maxRestSeconds: Int
    public var tempo: TempoPrescription
    public var condition: SlotCondition
    public var slotNote: BilingualText?

    public init(
        id: UUID = UUID(),
        exerciseID: UUID,
        scheme: SetScheme,
        maxWorkingSetsInAccumulation: Int? = nil,
        warmup: WarmupPrescription = .none,
        targetRIR: Int,
        minRestSeconds: Int,
        maxRestSeconds: Int? = nil,
        tempo: TempoPrescription = .controlledHypertrophy,
        condition: SlotCondition = .required,
        slotNote: BilingualText? = nil
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.scheme = scheme
        self.maxWorkingSetsInAccumulation = maxWorkingSetsInAccumulation
        self.warmup = warmup
        self.targetRIR = targetRIR
        self.minRestSeconds = minRestSeconds
        self.maxRestSeconds = maxRestSeconds ?? minRestSeconds
        self.tempo = tempo
        self.condition = condition
        self.slotNote = slotNote
    }
}

public struct WorkoutModuleBlueprint: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var code: String
    public var title: BilingualText
    public var slots: [ModuleExerciseSlot]

    public init(id: UUID = UUID(), code: String, title: BilingualText, slots: [ModuleExerciseSlot]) {
        self.id = id
        self.code = code
        self.title = title
        self.slots = slots
    }
}

/// Универсальный пресет тренировочной программы (для PureGym A–E и будущих авторских программ).
public struct ProgramTemplate: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var slug: String
    public var name: BilingualText
    public var recommendedDaysPerWeek: Int
    public var defaultMesocycleWeeks: Int
    public var modules: [WorkoutModuleBlueprint]

    public init(
        id: UUID = UUID(),
        slug: String,
        name: BilingualText,
        recommendedDaysPerWeek: Int,
        defaultMesocycleWeeks: Int = 6,
        modules: [WorkoutModuleBlueprint]
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.recommendedDaysPerWeek = recommendedDaysPerWeek
        self.defaultMesocycleWeeks = defaultMesocycleWeeks
        self.modules = modules
    }
}
