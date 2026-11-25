import Foundation

public enum MacrocyclePhase: String, Codable, Sendable, CaseIterable {
    case hypertrophy
    case cut
    case strength
    case maintenance
}

public enum MesocycleWeekRole: String, Codable, Sendable, Equatable {
    case acclimation    // Неделя 1: MEV, RIR 2
    case accumulation   // Недели 2–4: MAV, RIR 0–1
    case overreaching   // Опциональная пиковая неделя перед разгрузкой
    case deload         // Разгрузка: 100% веса, 50% рабочих подходов, RIR 3–4
}

public struct ModuleExerciseSlot: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var exerciseID: UUID
    public var scheme: SetScheme
    public var targetRIR: Int

    public init(id: UUID = UUID(), exerciseID: UUID, scheme: SetScheme, targetRIR: Int) {
        self.id = id
        self.exerciseID = exerciseID
        self.scheme = scheme
        self.targetRIR = targetRIR
    }
}

public struct WorkoutModuleBlueprint: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var code: String
    public var title: String
    public var slots: [ModuleExerciseSlot]

    public init(id: UUID = UUID(), code: String, title: String, slots: [ModuleExerciseSlot]) {
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
    public var name: String
    public var recommendedDaysPerWeek: Int
    public var defaultMesocycleWeeks: Int
    public var modules: [WorkoutModuleBlueprint]

    public init(
        id: UUID = UUID(),
        slug: String,
        name: String,
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
