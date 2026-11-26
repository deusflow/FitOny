import Foundation
import FitOnyCore

/// Ошибки локального слоя хранения FitOnyStorage.
public enum FitOnyDatabaseError: Error, LocalizedError, Sendable, Equatable {
    case emptyProgramCatalog
    case invalidEncodedPayload(entity: String)
    case workoutSessionNotFound(UUID)

    public var errorDescription: String? {
        switch self {
        case .emptyProgramCatalog:
            return "Program catalog has no active program."
        case let .invalidEncodedPayload(entity):
            return "Failed to decode persisted JSON payload for \(entity)."
        case let .workoutSessionNotFound(id):
            return "Workout session not found: \(id.uuidString)"
        }
    }
}

/// Чистый value-type снимок настроек атлета и состояния текущего мезоцикла.
public struct AthletePreferencesSnapshot: Codable, Sendable, Equatable {
    public static let defaultKey = "default"

    public var profile: PhysiologicalProfile
    public var activePhase: MacrocyclePhase
    public var activeProgramID: UUID?
    public var currentMesocycleWeek: Int
    public var totalMesocycleWeeks: Int
    public var lastCompletedModuleCode: String?
    public var selectedThemeID: String
    public var primaryLanguage: AppLanguage
    public var showSecondaryRussianHint: Bool
    public var autoDarkInEveningOrWorkout: Bool
    public var didSeedBuiltInCatalog: Bool
    public var updatedAt: Date

    public init(
        profile: PhysiologicalProfile = .natural,
        activePhase: MacrocyclePhase = .hypertrophy,
        activeProgramID: UUID? = nil,
        currentMesocycleWeek: Int = 1,
        totalMesocycleWeeks: Int = 6,
        lastCompletedModuleCode: String? = nil,
        selectedThemeID: String = "fitOnyPink",
        primaryLanguage: AppLanguage = .da,
        showSecondaryRussianHint: Bool = true,
        autoDarkInEveningOrWorkout: Bool = true,
        didSeedBuiltInCatalog: Bool = false,
        updatedAt: Date = .now
    ) {
        self.profile = profile
        self.activePhase = activePhase
        self.activeProgramID = activeProgramID
        self.currentMesocycleWeek = max(1, min(6, currentMesocycleWeek))
        self.totalMesocycleWeeks = max(4, min(6, totalMesocycleWeeks))
        self.lastCompletedModuleCode = lastCompletedModuleCode
        self.selectedThemeID = selectedThemeID
        self.primaryLanguage = primaryLanguage
        self.showSecondaryRussianHint = showSecondaryRussianHint
        self.autoDarkInEveningOrWorkout = autoDarkInEveningOrWorkout
        self.didSeedBuiltInCatalog = didSeedBuiltInCatalog
        self.updatedAt = updatedAt
    }
}

/// Заголовок сохранённой тренировочной сессии (активной или завершённой).
public struct WorkoutSessionRecord: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var programID: UUID
    public var moduleCode: String
    public var moduleTitle: BilingualText
    public var weekNumber: Int
    public var weekRole: MesocycleWeekRole
    public var phase: MacrocyclePhase
    public var startedAt: Date
    public var finishedAt: Date?
    public var isCompleted: Bool
    public var notes: String?

    public init(
        id: UUID = UUID(),
        programID: UUID,
        moduleCode: String,
        moduleTitle: BilingualText,
        weekNumber: Int,
        weekRole: MesocycleWeekRole,
        phase: MacrocyclePhase,
        startedAt: Date = .now,
        finishedAt: Date? = nil,
        isCompleted: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.programID = programID
        self.moduleCode = moduleCode
        self.moduleTitle = moduleTitle
        self.weekNumber = weekNumber
        self.weekRole = weekRole
        self.phase = phase
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.isCompleted = isCompleted
        self.notes = notes
    }
}
