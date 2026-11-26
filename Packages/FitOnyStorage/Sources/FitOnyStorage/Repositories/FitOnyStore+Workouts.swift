import Foundation
import SwiftData
import FitOnyCore

extension FitOnyStore {
    // MARK: - Workout Sessions

    @discardableResult
    public func startWorkoutSession(
        id: UUID = UUID(),
        programID: UUID,
        moduleCode: String,
        moduleTitle: BilingualText,
        weekNumber: Int,
        weekRole: MesocycleWeekRole,
        phase: MacrocyclePhase,
        startedAt: Date = .now
    ) throws -> WorkoutSessionRecord {
        let targetID = id
        let descriptor = FetchDescriptor<SDWorkoutSessionRecord>(
            predicate: #Predicate { $0.id == targetID }
        )

        if let existing = try fetchFirst(descriptor) {
            return try mapSession(existing)
        }

        let titleJSON = try encode(moduleTitle)
        let record = SDWorkoutSessionRecord(
            id: id,
            programID: programID,
            moduleCode: moduleCode,
            moduleTitleJSON: titleJSON,
            weekNumber: weekNumber,
            weekRoleRaw: weekRole.rawValue,
            phaseRaw: phase.rawValue,
            startedAt: startedAt,
            finishedAt: nil,
            isCompleted: false
        )
        context.insert(record)
        try context.save()
        return try mapSession(record)
    }

    public func completeWorkoutSession(
        id: UUID,
        finishedAt: Date = .now,
        notes: String? = nil
    ) throws {
        let targetID = id
        let descriptor = FetchDescriptor<SDWorkoutSessionRecord>(
            predicate: #Predicate { $0.id == targetID }
        )
        guard let record = try fetchFirst(descriptor) else {
            throw FitOnyDatabaseError.workoutSessionNotFound(id)
        }

        record.isCompleted = true
        record.finishedAt = finishedAt
        if let notes {
            record.notes = notes
        }

        let prefs = try ensurePreferencesRecord()
        prefs.lastCompletedModuleCode = record.moduleCode
        prefs.updatedAt = .now

        try context.save()
    }

    public func fetchWorkoutSessions(limit: Int? = nil) throws -> [WorkoutSessionRecord] {
        var descriptor = FetchDescriptor<SDWorkoutSessionRecord>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }
        let records = try context.fetch(descriptor)
        return try records.map(mapSession)
    }

    private func mapSession(_ record: SDWorkoutSessionRecord) throws -> WorkoutSessionRecord {
        let title = try decode(BilingualText.self, from: record.moduleTitleJSON, entity: "BilingualText")
        return WorkoutSessionRecord(
            id: record.id,
            programID: record.programID,
            moduleCode: record.moduleCode,
            moduleTitle: title,
            weekNumber: record.weekNumber,
            weekRole: MesocycleWeekRole(rawValue: record.weekRoleRaw) ?? .acclimation,
            phase: MacrocyclePhase(rawValue: record.phaseRaw) ?? .hypertrophy,
            startedAt: record.startedAt,
            finishedAt: record.finishedAt,
            isCompleted: record.isCompleted,
            notes: record.notes
        )
    }

    // MARK: - Completed Sets (Idempotent)

    public func recordCompletedSet(_ set: CompletedSetRecord) throws {
        let targetID = set.id
        let descriptor = FetchDescriptor<SDCompletedSetRecord>(
            predicate: #Predicate { $0.id == targetID }
        )

        if let existing = try fetchFirst(descriptor) {
            existing.sessionID = set.sessionID
            existing.exerciseID = set.exerciseID
            existing.equipmentVariantRaw = set.equipmentVariant.rawValue
            existing.setIndex = set.setIndex
            existing.isWarmup = set.isWarmup
            existing.isDropStep = set.isDropStep
            existing.weightKg = set.weightKg
            existing.completedReps = set.completedReps
            existing.leftSideReps = set.leftSideReps
            existing.rightSideReps = set.rightSideReps
            existing.rir = set.rir
            existing.peakHeartRate = set.peakHeartRate
            existing.hrr60Drop = set.hrr60Drop
            existing.concentricSlowdownPercent = set.concentricSlowdownPercent
            existing.completedAt = set.completedAt
        } else {
            context.insert(
                SDCompletedSetRecord(
                    id: set.id,
                    sessionID: set.sessionID,
                    exerciseID: set.exerciseID,
                    equipmentVariantRaw: set.equipmentVariant.rawValue,
                    setIndex: set.setIndex,
                    isWarmup: set.isWarmup,
                    isDropStep: set.isDropStep,
                    weightKg: set.weightKg,
                    completedReps: set.completedReps,
                    leftSideReps: set.leftSideReps,
                    rightSideReps: set.rightSideReps,
                    rir: set.rir,
                    peakHeartRate: set.peakHeartRate,
                    hrr60Drop: set.hrr60Drop,
                    concentricSlowdownPercent: set.concentricSlowdownPercent,
                    completedAt: set.completedAt
                )
            )
        }
        try context.save()
    }

    public func fetchCompletedSets(
        sessionID: UUID? = nil,
        since: Date? = nil
    ) throws -> [CompletedSetRecord] {
        let descriptor: FetchDescriptor<SDCompletedSetRecord>
        switch (sessionID, since) {
        case let (sid?, date?):
            descriptor = FetchDescriptor<SDCompletedSetRecord>(
                predicate: #Predicate { $0.sessionID == sid && $0.completedAt >= date },
                sortBy: [SortDescriptor(\.completedAt), SortDescriptor(\.setIndex)]
            )
        case let (sid?, nil):
            descriptor = FetchDescriptor<SDCompletedSetRecord>(
                predicate: #Predicate { $0.sessionID == sid },
                sortBy: [SortDescriptor(\.completedAt), SortDescriptor(\.setIndex)]
            )
        case let (nil, date?):
            descriptor = FetchDescriptor<SDCompletedSetRecord>(
                predicate: #Predicate { $0.completedAt >= date },
                sortBy: [SortDescriptor(\.completedAt), SortDescriptor(\.setIndex)]
            )
        case (nil, nil):
            descriptor = FetchDescriptor<SDCompletedSetRecord>(
                sortBy: [SortDescriptor(\.completedAt), SortDescriptor(\.setIndex)]
            )
        }

        let records = try context.fetch(descriptor)
        return records.map {
            CompletedSetRecord(
                id: $0.id,
                sessionID: $0.sessionID,
                exerciseID: $0.exerciseID,
                equipmentVariant: EquipmentVariant(rawValue: $0.equipmentVariantRaw) ?? .primary,
                setIndex: $0.setIndex,
                isWarmup: $0.isWarmup,
                isDropStep: $0.isDropStep,
                weightKg: $0.weightKg,
                completedReps: $0.completedReps,
                leftSideReps: $0.leftSideReps,
                rightSideReps: $0.rightSideReps,
                rir: $0.rir,
                peakHeartRate: $0.peakHeartRate,
                hrr60Drop: $0.hrr60Drop,
                concentricSlowdownPercent: $0.concentricSlowdownPercent,
                completedAt: $0.completedAt
            )
        }
    }

    // MARK: - Exercise Load States

    public func fetchLoadStates() throws -> [ExerciseEquipmentKey: ExerciseLoadState] {
        let records = try context.fetch(FetchDescriptor<SDExerciseLoadStateRecord>())
        var result: [ExerciseEquipmentKey: ExerciseLoadState] = [:]
        result.reserveCapacity(records.count)

        for record in records {
            let variant = EquipmentVariant(rawValue: record.equipmentVariantRaw) ?? .primary
            let state = ExerciseLoadState(
                exerciseID: record.exerciseID,
                equipmentVariant: variant,
                baselineWorkingWeightKg: record.baselineWorkingWeightKg,
                sessionTargetWeightKg: record.sessionTargetWeightKg
            )
            result[state.key] = state
        }
        return result
    }

    public func upsertLoadState(_ state: ExerciseLoadState) throws {
        let key = "\(state.exerciseID.uuidString)::\(state.equipmentVariant.rawValue)"
        let descriptor = FetchDescriptor<SDExerciseLoadStateRecord>(
            predicate: #Predicate { $0.compositeKey == key }
        )
        if let existing = try fetchFirst(descriptor) {
            existing.baselineWorkingWeightKg = state.baselineWorkingWeightKg
            existing.sessionTargetWeightKg = state.sessionTargetWeightKg
            existing.updatedAt = .now
        } else {
            context.insert(
                SDExerciseLoadStateRecord(
                    compositeKey: key,
                    exerciseID: state.exerciseID,
                    equipmentVariantRaw: state.equipmentVariant.rawValue,
                    baselineWorkingWeightKg: state.baselineWorkingWeightKg,
                    sessionTargetWeightKg: state.sessionTargetWeightKg
                )
            )
        }
        try context.save()
    }

    // MARK: - Night Biometrics & Morning Check-ins

    public func recordNightBiometrics(_ biometrics: NightBiometrics) throws {
        let key = dayKey(for: biometrics.date)
        let descriptor = FetchDescriptor<SDNightBiometricsRecord>(
            predicate: #Predicate { $0.dayKey == key }
        )
        if let existing = try fetchFirst(descriptor) {
            existing.date = biometrics.date
            existing.nocturnalHRVms = biometrics.nocturnalHRVms
            existing.restingHeartRateBPM = biometrics.restingHeartRateBPM
            existing.sleepDurationMinutes = biometrics.sleepDurationMinutes
            existing.deepAndREMMinutes = biometrics.deepAndREMMinutes
            existing.wristTemperatureCelsius = biometrics.wristTemperatureCelsius
            existing.respiratoryRateBrPM = biometrics.respiratoryRateBrPM
        } else {
            context.insert(
                SDNightBiometricsRecord(
                    dayKey: key,
                    date: biometrics.date,
                    nocturnalHRVms: biometrics.nocturnalHRVms,
                    restingHeartRateBPM: biometrics.restingHeartRateBPM,
                    sleepDurationMinutes: biometrics.sleepDurationMinutes,
                    deepAndREMMinutes: biometrics.deepAndREMMinutes,
                    wristTemperatureCelsius: biometrics.wristTemperatureCelsius,
                    respiratoryRateBrPM: biometrics.respiratoryRateBrPM
                )
            )
        }
        try context.save()
    }

    public func fetchNightBiometrics(days: Int = 28, endingAt: Date = .now) throws -> [NightBiometrics] {
        let start = Calendar.current.date(byAdding: .day, value: -max(1, days), to: endingAt) ?? .distantPast
        let descriptor = FetchDescriptor<SDNightBiometricsRecord>(
            predicate: #Predicate { $0.date >= start && $0.date <= endingAt },
            sortBy: [SortDescriptor(\.date)]
        )
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

    public func recordMorningCheckIn(_ checkIn: MorningCheckIn) throws {
        let key = dayKey(for: checkIn.recordedAt)
        let descriptor = FetchDescriptor<SDMorningCheckInRecord>(
            predicate: #Predicate { $0.dayKey == key }
        )
        if let existing = try fetchFirst(descriptor) {
            existing.recordedAt = checkIn.recordedAt
            existing.energyRating = checkIn.energyRating
            existing.sorenessRating = checkIn.sorenessRating
            existing.stressRating = checkIn.stressRating
        } else {
            context.insert(
                SDMorningCheckInRecord(
                    dayKey: key,
                    recordedAt: checkIn.recordedAt,
                    energyRating: checkIn.energyRating,
                    sorenessRating: checkIn.sorenessRating,
                    stressRating: checkIn.stressRating
                )
            )
        }
        try context.save()
    }

    public func fetchMorningCheckIn(for date: Date = .now) throws -> MorningCheckIn? {
        let key = dayKey(for: date)
        let descriptor = FetchDescriptor<SDMorningCheckInRecord>(
            predicate: #Predicate { $0.dayKey == key }
        )
        guard let record = try fetchFirst(descriptor) else {
            return nil
        }
        return MorningCheckIn(
            energyRating: record.energyRating,
            sorenessRating: record.sorenessRating,
            stressRating: record.stressRating,
            recordedAt: record.recordedAt
        )
    }

    // MARK: - Next Session Composition Bridge

    /// Собирает готовую тренировку на сегодня напрямую из базы данных SwiftData через FitOnyCore.SessionComposer.
    public func composeNextSession(
        referenceDate: Date = .now,
        plannedDirectMusclesNext24h: Set<MuscleGroup> = [],
        acceptedAdaptationSlotIDs: Set<UUID>? = nil
    ) throws -> ComposedWorkoutSession? {
        let prefs = try fetchPreferences()
        let catalog = try fetchCatalog()

        guard let program = (prefs.activeProgramID.flatMap { catalog.program(id: $0) }) ?? catalog.programs.first,
              let module = program.nextModuleInQueue(afterCompletedModuleCode: prefs.lastCompletedModuleCode) else {
            return nil
        }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: referenceDate) ?? .distantPast
        let weeklySets = try fetchCompletedSets(since: sevenDaysAgo)
        let recentCutoff = Calendar.current.date(byAdding: .hour, value: -72, to: referenceDate) ?? .distantPast
        let recentSets = weeklySets.filter { $0.completedAt >= recentCutoff }

        let loadStates = try fetchLoadStates()
        let variants = try selectedVariantsBySlotID()

        return SessionComposer.compose(
            module: module,
            program: program,
            catalog: catalog,
            weekNumber: prefs.currentMesocycleWeek,
            totalWeeks: prefs.totalMesocycleWeeks,
            phase: prefs.activePhase,
            profile: prefs.profile,
            recentSets: recentSets,
            weeklySets: weeklySets,
            plannedDirectMusclesNext24h: plannedDirectMusclesNext24h,
            acceptedAdaptationSlotIDs: acceptedAdaptationSlotIDs,
            selectedVariantsBySlotID: variants,
            loadStatesByKey: loadStates,
            referenceDate: referenceDate
        )
    }
}
