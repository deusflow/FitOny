import Foundation
import SwiftData
import FitOnyCore

extension FitOnyStore {
    /// Идемпотентно загружает встроенные упражнения и программу PureGym «Pumpet Pony» при первом запуске.
    public func seedBuiltInCatalogIfNeeded(catalog: ProgramCatalog = .builtIn) throws {
        let prefsRecord = try ensurePreferencesRecord()

        if !prefsRecord.didSeedBuiltInCatalog {
            for exercise in catalog.exercisesByID.values {
                try insertExerciseIfMissing(exercise, isCustom: false)
            }

            for program in catalog.programs {
                try insertProgramIfMissing(program)
            }

            if prefsRecord.activeProgramID == nil {
                prefsRecord.activeProgramID = catalog.programs.first?.id
            }
            prefsRecord.didSeedBuiltInCatalog = true
            prefsRecord.updatedAt = .now
            try context.save()
            return
        }

        // На повторных запусках проверяем только отсутствие активной программы без перезаписи правок пользователя.
        if prefsRecord.activeProgramID == nil {
            let existingPrograms = try context.fetch(FetchDescriptor<SDProgramRecord>())
            if let first = existingPrograms.first {
                prefsRecord.activeProgramID = first.id
                prefsRecord.updatedAt = .now
                try context.save()
            }
        }
    }

    /// Возвращает актуальный каталог всех сохранённых упражнений и программ.
    public func fetchCatalog() throws -> ProgramCatalog {
        let exerciseRecords = try context.fetch(FetchDescriptor<SDExerciseRecord>())
        let programRecords = try context.fetch(
            FetchDescriptor<SDProgramRecord>(sortBy: [SortDescriptor(\.slug)])
        )

        let exercises = try exerciseRecords.map {
            try decode(ExerciseDefinition.self, from: $0.payloadJSON, entity: "ExerciseDefinition")
        }
        let programs = try programRecords.map {
            try decode(ProgramTemplate.self, from: $0.payloadJSON, entity: "ProgramTemplate")
        }

        return ProgramCatalog(exercises: exercises, programs: programs)
    }

    public func fetchProgram(id: UUID) throws -> ProgramTemplate? {
        let targetID = id
        let descriptor = FetchDescriptor<SDProgramRecord>(
            predicate: #Predicate { $0.id == targetID }
        )
        guard let record = try fetchFirst(descriptor) else {
            return nil
        }
        return try decode(ProgramTemplate.self, from: record.payloadJSON, entity: "ProgramTemplate")
    }

    public func upsertExercise(_ exercise: ExerciseDefinition, isCustom: Bool = true) throws {
        let targetID = exercise.id
        let payload = try encode(exercise)
        let descriptor = FetchDescriptor<SDExerciseRecord>(
            predicate: #Predicate { $0.id == targetID }
        )

        if let existing = try fetchFirst(descriptor) {
            existing.code = exercise.code
            existing.isCompound = exercise.isCompound
            existing.payloadJSON = payload
            existing.updatedAt = .now
        } else {
            context.insert(
                SDExerciseRecord(
                    id: exercise.id,
                    code: exercise.code,
                    isCustom: isCustom,
                    isCompound: exercise.isCompound,
                    payloadJSON: payload
                )
            )
        }
        try context.save()
    }

    public func upsertProgram(_ program: ProgramTemplate) throws {
        let targetID = program.id
        let payload = try encode(program)
        let descriptor = FetchDescriptor<SDProgramRecord>(
            predicate: #Predicate { $0.id == targetID }
        )

        if let existing = try fetchFirst(descriptor) {
            existing.slug = program.slug
            existing.isCustom = program.isCustom
            existing.recommendedDaysPerWeek = program.recommendedDaysPerWeek
            existing.defaultMesocycleWeeks = program.defaultMesocycleWeeks
            existing.payloadJSON = payload
            existing.updatedAt = .now
        } else {
            context.insert(
                SDProgramRecord(
                    id: program.id,
                    slug: program.slug,
                    isCustom: program.isCustom,
                    recommendedDaysPerWeek: program.recommendedDaysPerWeek,
                    defaultMesocycleWeeks: program.defaultMesocycleWeeks,
                    payloadJSON: payload
                )
            )
        }
        try context.save()
    }

    public func deleteCustomProgram(id: UUID) throws {
        let targetID = id
        let descriptor = FetchDescriptor<SDProgramRecord>(
            predicate: #Predicate { $0.id == targetID && $0.isCustom == true }
        )
        if let existing = try fetchFirst(descriptor) {
            context.delete(existing)
            let prefs = try ensurePreferencesRecord()
            if prefs.activeProgramID == targetID {
                let fallback = try context.fetch(FetchDescriptor<SDProgramRecord>()).first
                prefs.activeProgramID = fallback?.id
                prefs.updatedAt = .now
            }
            try context.save()
        }
    }

    private func insertExerciseIfMissing(_ exercise: ExerciseDefinition, isCustom: Bool) throws {
        let targetID = exercise.id
        let descriptor = FetchDescriptor<SDExerciseRecord>(
            predicate: #Predicate { $0.id == targetID }
        )
        guard try fetchFirst(descriptor) == nil else { return }

        let payload = try encode(exercise)
        context.insert(
            SDExerciseRecord(
                id: exercise.id,
                code: exercise.code,
                isCustom: isCustom,
                isCompound: exercise.isCompound,
                payloadJSON: payload
            )
        )
    }

    private func insertProgramIfMissing(_ program: ProgramTemplate) throws {
        let targetID = program.id
        let descriptor = FetchDescriptor<SDProgramRecord>(
            predicate: #Predicate { $0.id == targetID }
        )
        guard try fetchFirst(descriptor) == nil else { return }

        let payload = try encode(program)
        context.insert(
            SDProgramRecord(
                id: program.id,
                slug: program.slug,
                isCustom: program.isCustom,
                recommendedDaysPerWeek: program.recommendedDaysPerWeek,
                defaultMesocycleWeeks: program.defaultMesocycleWeeks,
                payloadJSON: payload
            )
        )
    }
}
