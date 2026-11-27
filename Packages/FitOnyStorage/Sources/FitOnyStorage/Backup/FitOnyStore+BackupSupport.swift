import Foundation
import SwiftData
import FitOnyCore

/// Полный сериализуемый слепок открытого контура базы данных (тренировки, циклы, заметки и веса).
public struct FitOnyPublicBackupPayload: Codable, Sendable, Equatable {
    public var preferences: AthletePreferencesSnapshot
    public var exercises: [ExerciseDefinition]
    public var customExerciseIDs: Set<UUID>
    public var programs: [ProgramTemplate]
    public var loadStates: [ExerciseLoadState]
    public var slotVariants: [UUID: EquipmentVariant]
    public var sessions: [WorkoutSessionRecord]
    public var completedSets: [CompletedSetRecord]
    public var nightBiometrics: [NightBiometrics]
    public var morningCheckIns: [MorningCheckIn]

    public init(
        preferences: AthletePreferencesSnapshot,
        exercises: [ExerciseDefinition],
        customExerciseIDs: Set<UUID>,
        programs: [ProgramTemplate],
        loadStates: [ExerciseLoadState],
        slotVariants: [UUID: EquipmentVariant],
        sessions: [WorkoutSessionRecord],
        completedSets: [CompletedSetRecord],
        nightBiometrics: [NightBiometrics],
        morningCheckIns: [MorningCheckIn]
    ) {
        self.preferences = preferences
        self.exercises = exercises
        self.customExerciseIDs = customExerciseIDs
        self.programs = programs
        self.loadStates = loadStates
        self.slotVariants = slotVariants
        self.sessions = sessions
        self.completedSets = completedSets
        self.nightBiometrics = nightBiometrics
        self.morningCheckIns = morningCheckIns
    }
}

extension FitOnyStore {
    /// Собирает полный снимок всех открытых данных базы для экспорта в `.fitony` или `.fitonyvault`.
    public func exportPublicBackupPayload() throws -> FitOnyPublicBackupPayload {
        let preferences = try fetchPreferences()
        let exerciseRecords = try context.fetch(
            FetchDescriptor<SDExerciseRecord>(sortBy: [SortDescriptor(\.code)])
        )
        let exercises = try exerciseRecords.map {
            try decode(ExerciseDefinition.self, from: $0.payloadJSON, entity: "ExerciseDefinition")
        }
        let customIDs = Set(exerciseRecords.filter(\.isCustom).map(\.id))

        let catalog = try fetchCatalog()
        let loadStates = try fetchLoadStates().values.sorted {
            $0.exerciseID.uuidString < $1.exerciseID.uuidString
        }
        let slotVariants = try selectedVariantsBySlotID()
        let sessions = try fetchWorkoutSessions()
        let completedSets = try fetchCompletedSets()
        let nightBiometrics = try fetchAllNightBiometrics()
        let morningCheckIns = try fetchAllMorningCheckIns()

        return FitOnyPublicBackupPayload(
            preferences: preferences,
            exercises: exercises,
            customExerciseIDs: customIDs,
            programs: catalog.programs,
            loadStates: loadStates,
            slotVariants: slotVariants,
            sessions: sessions,
            completedSets: completedSets,
            nightBiometrics: nightBiometrics,
            morningCheckIns: morningCheckIns
        )
    }

    /// Атомарно заменяет содержимое открытой базы данными из проверенной резервной копии.
    public func restorePublicBackupPayload(_ payload: FitOnyPublicBackupPayload) throws {
        if let storeURL {
            let backupsDir = storeURL
                .deletingLastPathComponent()
                .appendingPathComponent("Backups/PreRestore", isDirectory: true)
            _ = try? DatabaseSnapshotService.createSnapshot(
                storeURL: storeURL,
                backupsDirectoryURL: backupsDir,
                label: "pre-restore"
            )
        }

        try deleteAllRecords(of: SDCompletedSetRecord.self)
        try deleteAllRecords(of: SDWorkoutSessionRecord.self)
        try deleteAllRecords(of: SDExerciseLoadStateRecord.self)
        try deleteAllRecords(of: SDSlotVariantPreference.self)
        try deleteAllRecords(of: SDNightBiometricsRecord.self)
        try deleteAllRecords(of: SDMorningCheckInRecord.self)
        try deleteAllRecords(of: SDProgramRecord.self)
        try deleteAllRecords(of: SDExerciseRecord.self)
        try deleteAllRecords(of: SDUserPreferences.self)
        try context.save()

        for exercise in payload.exercises {
            let isCustom = payload.customExerciseIDs.contains(exercise.id)
            try upsertExercise(exercise, isCustom: isCustom)
        }

        for program in payload.programs {
            try upsertProgram(program)
        }

        for state in payload.loadStates {
            try upsertLoadState(state)
        }

        for (slotID, variant) in payload.slotVariants {
            try setSelectedVariant(variant, forSlotID: slotID)
        }

        for session in payload.sessions {
            let titleJSON = try encode(session.moduleTitle)
            context.insert(
                SDWorkoutSessionRecord(
                    id: session.id,
                    programID: session.programID,
                    moduleCode: session.moduleCode,
                    moduleTitleJSON: titleJSON,
                    weekNumber: session.weekNumber,
                    weekRoleRaw: session.weekRole.rawValue,
                    phaseRaw: session.phase.rawValue,
                    startedAt: session.startedAt,
                    finishedAt: session.finishedAt,
                    isCompleted: session.isCompleted,
                    notes: session.notes
                )
            )
        }

        for set in payload.completedSets {
            try recordCompletedSet(set)
        }

        for night in payload.nightBiometrics {
            try recordNightBiometrics(night)
        }

        for checkIn in payload.morningCheckIns {
            try recordMorningCheckIn(checkIn)
        }

        _ = try updatePreferences { prefs in
            prefs = payload.preferences
            prefs.didSeedBuiltInCatalog = true
        }

        // Гарантируем наличие базового каталога, если импортируется частичный старый архив
        try seedBuiltInCatalogIfNeeded()
        try context.save()
    }

    internal func fetchAllNightBiometrics() throws -> [NightBiometrics] {
        let descriptor = FetchDescriptor<SDNightBiometricsRecord>(sortBy: [SortDescriptor(\.date)])
        return try context.fetch(descriptor).map {
            NightBiometrics(
                date: $0.date,
                nocturnalHRVms: $0.nocturnalHRVms,
                restingHeartRateBPM: $0.restingHeartRateBPM,
                sleepDurationMinutes: $0.sleepDurationMinutes,
                deepAndREMMinutes: $0.deepAndREMMinutes,
                wristTemperatureCelsius: $0.wristTemperatureCelsius,
                respiratoryRateBrPM: $0.respiratoryRateBrPM
            )
        }
    }

    internal func fetchAllMorningCheckIns() throws -> [MorningCheckIn] {
        let descriptor = FetchDescriptor<SDMorningCheckInRecord>(sortBy: [SortDescriptor(\.recordedAt)])
        return try context.fetch(descriptor).map {
            MorningCheckIn(
                energyRating: $0.energyRating,
                sorenessRating: $0.sorenessRating,
                stressRating: $0.stressRating,
                recordedAt: $0.recordedAt
            )
        }
    }

    private func deleteAllRecords<M: PersistentModel>(of modelType: M.Type) throws {
        let items = try context.fetch(FetchDescriptor<M>())
        for item in items {
            context.delete(item)
        }
    }
}
