import Foundation
import Testing
import FitOnyCore
@testable import FitOnyStorage

@MainActor
@Suite("FitOnyStorage SwiftData Persistence")
struct FitOnyStorageTests {
    private func makeTemporaryDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FitOnyStorageTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("Persistent SQLite store seeds Pumpet Pony once and survives restart without duplicates")
    func persistentStoreRestartAndNoDuplicateSeeding() throws {
        let tempDir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let customProgramID = UUID()
        let customProgram = ProgramTemplate(
            id: customProgramID,
            slug: "custom-upper-lower",
            name: .custom("Custom Upper Lower"),
            isCustom: true,
            recommendedDaysPerWeek: 4,
            modules: [
                WorkoutModuleBlueprint(
                    code: "U1",
                    title: .custom("Upper 1"),
                    slots: []
                )
            ]
        )

        do {
            let store = try FitOnyStore.makePersistentStore(directoryURL: tempDir)
            let catalog = try store.fetchCatalog()
            #expect(catalog.exercisesByID.count == PumpetPonyCatalog.exercises.count)
            #expect(catalog.programs.count == 1)
            #expect(catalog.programs.first?.slug == PumpetPonyCatalog.programTemplate.slug)

            try store.updatePreferences { prefs in
                prefs.activePhase = .cut
                prefs.currentMesocycleWeek = 3
                prefs.totalMesocycleWeeks = 5
                prefs.selectedThemeID = "amoledDark"
                prefs.primaryLanguage = .ru
                prefs.profile = .enhanced
            }
            try store.upsertProgram(customProgram)
            // Повторный вызов сидинга не должен дублировать или перетирать настройки
            try store.seedBuiltInCatalogIfNeeded()
        }

        // Имитация холодного перезапуска приложения (новый ModelContainer на ту же SQLite-папку)
        let reopenedStore = try FitOnyStore.makePersistentStore(directoryURL: tempDir)
        let reopenedCatalog = try reopenedStore.fetchCatalog()
        let reopenedPrefs = try reopenedStore.fetchPreferences()

        #expect(reopenedCatalog.exercisesByID.count == PumpetPonyCatalog.exercises.count)
        #expect(reopenedCatalog.programs.count == 2)
        #expect(reopenedCatalog.program(id: customProgramID)?.name == .custom("Custom Upper Lower"))
        #expect(reopenedPrefs.activePhase == .cut)
        #expect(reopenedPrefs.currentMesocycleWeek == 3)
        #expect(reopenedPrefs.totalMesocycleWeeks == 5)
        #expect(reopenedPrefs.selectedThemeID == "amoledDark")
        #expect(reopenedPrefs.primaryLanguage == .ru)
        #expect(reopenedPrefs.profile == .enhanced)
    }

    @Test("Completed sets are idempotent and equipment variant weights persist independently")
    func idempotentSetsAndIndependentEquipmentWeights() throws {
        let store = try FitOnyStore.makeInMemoryStore()
        let benchID = PumpetPonyCatalog.ExerciseIDs.inclineChestPress
        let sessionID = UUID()

        let primaryState = ExerciseLoadState(
            exerciseID: benchID,
            equipmentVariant: .primary,
            baselineWorkingWeightKg: 34,
            sessionTargetWeightKg: 34
        )
        let altState = ExerciseLoadState(
            exerciseID: benchID,
            equipmentVariant: .alternative,
            baselineWorkingWeightKg: 80,
            sessionTargetWeightKg: 75
        )
        try store.upsertLoadState(primaryState)
        try store.upsertLoadState(altState)

        let loadStates = try store.fetchLoadStates()
        #expect(loadStates[ExerciseEquipmentKey(exerciseID: benchID, variant: .primary)]?.baselineWorkingWeightKg == 34)
        #expect(loadStates[ExerciseEquipmentKey(exerciseID: benchID, variant: .alternative)]?.sessionTargetWeightKg == 75)

        let setID = UUID()
        let firstSave = CompletedSetRecord(
            id: setID,
            sessionID: sessionID,
            exerciseID: benchID,
            equipmentVariant: .primary,
            setIndex: 1,
            isWarmup: false,
            weightKg: 34,
            completedReps: 9,
            rir: 1
        )
        try store.recordCompletedSet(firstSave)

        // Повторная доставка того же UUID с Watch (например, уточнённый пульс) не должна создавать дубликат
        var duplicateDelivery = firstSave
        duplicateDelivery.peakHeartRate = 148
        try store.recordCompletedSet(duplicateDelivery)

        let savedSets = try store.fetchCompletedSets(sessionID: sessionID)
        #expect(savedSets.count == 1)
        #expect(savedSets.first?.peakHeartRate == 148)
    }

    @Test("Sessions, biometrics, check-ins, and SessionComposer bridge round-trip cleanly")
    func sessionsBiometricsAndComposeBridge() throws {
        let store = try FitOnyStore.makeInMemoryStore()
        let prefs = try store.fetchPreferences()
        let programID = try #require(prefs.activeProgramID)

        let session = try store.startWorkoutSession(
            programID: programID,
            moduleCode: "A",
            moduleTitle: PumpetPonyCatalog.moduleA.title,
            weekNumber: 1,
            weekRole: .acclimation,
            phase: .hypertrophy
        )
        try store.completeWorkoutSession(id: session.id, notes: "Felt strong")

        let sessions = try store.fetchWorkoutSessions()
        #expect(sessions.count == 1)
        #expect(sessions.first?.isCompleted == true)
        #expect(sessions.first?.notes == "Felt strong")

        let today = Date.now
        try store.recordNightBiometrics(
            NightBiometrics(
                date: today,
                nocturnalHRVms: 68,
                restingHeartRateBPM: 52,
                sleepDurationMinutes: 460
            )
        )
        try store.recordMorningCheckIn(
            MorningCheckIn(energyRating: 4, sorenessRating: 2, stressRating: 2, recordedAt: today)
        )

        #expect(try store.fetchNightBiometrics(days: 7, endingAt: today).count == 1)
        #expect(try store.fetchMorningCheckIn(for: today)?.energyRating == 4)

        // После завершения модуля A очередь ротации должна выдать модуль B
        let nextComposed = try store.composeNextSession(referenceDate: today)
        #expect(nextComposed?.moduleCode == "B")
        #expect(nextComposed?.exercises.isEmpty == false)
    }

    @Test("DatabaseSnapshotService creates pre-migration backup when schema version changes")
    func preMigrationSnapshotCreationAndPruning() throws {
        let tempDir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let backupsDir = tempDir.appendingPathComponent("Backups/PreMigration", isDirectory: true)
        let storeURL = tempDir.appendingPathComponent("FitOny.store")
        let markerURL = tempDir.appendingPathComponent("schema-version.txt")

        // Создаём фиктивный файл старой базы версии 0.9.0
        try Data("sqlite-dummy-v090".utf8).write(to: storeURL)
        try "0.9.0".write(to: markerURL, atomically: true, encoding: .utf8)

        let snapshotURL = try DatabaseSnapshotService.snapshotBeforeMigrationIfNeeded(
            storeURL: storeURL,
            backupsDirectoryURL: backupsDir,
            currentVersion: "1.0.0"
        )
        #expect(snapshotURL != nil)

        if let snapshotURL {
            let copiedStore = snapshotURL.appendingPathComponent("FitOny.store")
            #expect(FileManager.default.fileExists(atPath: copiedStore.path))
            #expect(snapshotURL.lastPathComponent.contains("pre-migration-0.9.0-to-1.0.0"))
        }

        // Если версия совпадает — повторный снимок не создаётся
        try DatabaseSnapshotService.recordSchemaVersion(storeURL: storeURL, version: "1.0.0")
        let secondRun = try DatabaseSnapshotService.snapshotBeforeMigrationIfNeeded(
            storeURL: storeURL,
            backupsDirectoryURL: backupsDir,
            currentVersion: "1.0.0"
        )
        #expect(secondRun == nil)
    }
}
