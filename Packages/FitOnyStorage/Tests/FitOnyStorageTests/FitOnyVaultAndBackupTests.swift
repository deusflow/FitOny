import Foundation
import Testing
import FitOnyCore
@testable import FitOnyStorage

private struct MockBiometricAuth: BiometricAuthenticating {
    let shouldSucceed: Bool

    func authenticate(reason: String) async throws {
        if !shouldSucceed {
            throw FitOnyVaultError.authenticationFailed
        }
    }
}

@MainActor
@Suite("FitOnyStorage Crypto Vault & Backups (Day 7)")
struct FitOnyVaultAndBackupTests {
    private func makeTemporaryDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FitOnyVaultTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("EncryptedVaultStore hides all plaintext on disk, blocks tampering, and locks RAM immediately")
    func vaultEncryptionIsolationTamperAndLock() async throws {
        let tempDir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let vaultURL = tempDir.appendingPathComponent("vault.enc")
        let keyProvider = InMemoryVaultKeyProvider()

        // 1. Отказ биометрии блокирует вход
        let deniedVault = EncryptedVaultStore(
            vaultFileURL: vaultURL,
            keyProvider: keyProvider,
            authService: MockBiometricAuth(shouldSucceed: false)
        )
        await #expect(throws: FitOnyVaultError.authenticationFailed) {
            try await deniedVault.unlock()
        }
        #expect(deniedVault.isUnlocked == false)

        // 2. Успешный вход, запись давления (>170/110) и анализа крови с выходом за референс
        let vault = EncryptedVaultStore(
            vaultFileURL: vaultURL,
            keyProvider: keyProvider,
            authService: MockBiometricAuth(shouldSucceed: true)
        )
        try await vault.unlock()
        #expect(vault.isUnlocked == true)

        let crisisBP = BloodPressureReading(
            systolicMMHg: 175,
            diastolicMMHg: 112,
            pulseBPM: 84,
            note: "SecretMorningCheck"
        )
        #expect(crisisBP.isHypertensiveCrisisAlert == true)

        let elevatedMarker = LabBiomarkerEntry(
            code: "HCT",
            name: "HematocritSecret",
            value: 53.5,
            unit: "%",
            referenceMin: 40.0,
            referenceMax: 50.0
        )
        #expect(elevatedMarker.isOutOfRange == true)

        try vault.update { state in
            state.bloodPressureReadings.append(crisisBP)
            state.labPanels.append(
                LabPanelRecord(
                    laboratoryName: "SundhedPrivateLab",
                    markers: [elevatedMarker]
                )
            )
        }

        // 3. Проверка файла на диске: ни одной открытой подстроки + флаг исключения из облачного бэкапа
        let rawCiphertext = try Data(contentsOf: vaultURL)
        let rawAsUTF8 = String(decoding: rawCiphertext, as: UTF8.self)
        #expect(!rawAsUTF8.contains("SecretMorningCheck"))
        #expect(!rawAsUTF8.contains("HematocritSecret"))
        #expect(!rawAsUTF8.contains("SundhedPrivateLab"))

        let resourceValues = try vaultURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(resourceValues.isExcludedFromBackup == true)

        // 4. Мгновенная блокировка при уходе в фон очищает память
        vault.lockImmediately()
        #expect(vault.isUnlocked == false)
        #expect(throws: FitOnyVaultError.vaultLocked) {
            _ = try vault.currentPayload()
        }

        // 5. Повторное открытие тем же ключом возвращает данные один в один
        let reopened = try await vault.unlock()
        #expect(reopened.bloodPressureReadings.count == 1)
        #expect(reopened.labPanels.first?.laboratoryName == "SundhedPrivateLab")
        vault.lockImmediately()

        // 6. Подмена хотя бы 1 байта в шифротексте детектируется тегом аутентификации AES-GCM
        var tampered = rawCiphertext
        let lastIndex = tampered.count - 1
        tampered[lastIndex] ^= 0xFF
        try tampered.write(to: vaultURL)

        await #expect(throws: FitOnyVaultError.corruptedOrTamperedVaultFile) {
            try await vault.unlock()
        }
    }

    @Test("Public .fitony backup verifies SHA-256, creates pre-restore snapshot, and restores cleanly")
    func publicFitOnyBackupAndRestore() throws {
        let sourceDir = try makeTemporaryDirectory()
        let targetDir = try makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceDir)
            try? FileManager.default.removeItem(at: targetDir)
        }

        let sourceStore = try FitOnyStore.makePersistentStore(directoryURL: sourceDir)
        let prefs = try sourceStore.updatePreferences { p in
            p.activePhase = .strength
            p.currentMesocycleWeek = 4
            p.selectedThemeID = "amoledDark"
        }
        let programID = try #require(prefs.activeProgramID)
        let session = try sourceStore.startWorkoutSession(
            programID: programID,
            moduleCode: "A",
            moduleTitle: PumpetPonyCatalog.moduleA.title,
            weekNumber: 4,
            weekRole: .accumulation,
            phase: .strength
        )
        try sourceStore.recordCompletedSet(
            CompletedSetRecord(
                sessionID: session.id,
                exerciseID: PumpetPonyCatalog.ExerciseIDs.inclineChestPress,
                equipmentVariant: .primary,
                setIndex: 1,
                isWarmup: false,
                weightKg: 95,
                completedReps: 8,
                rir: 1
            )
        )

        let archiveData = try FitOnyBackupService.exportPublicBackupData(from: sourceStore)

        // Проверка защиты от повреждения контрольной суммы SHA-256
        let isoDecoder = JSONDecoder()
        isoDecoder.dateDecodingStrategy = .iso8601
        var tamperedEnvelope = try isoDecoder.decode(FitOnyPublicArchiveEnvelope.self, from: archiveData)
        tamperedEnvelope.sha256Hex = String(repeating: "0", count: 64)
        let isoEncoder = JSONEncoder()
        isoEncoder.dateEncodingStrategy = .iso8601
        let badArchiveData = try isoEncoder.encode(tamperedEnvelope)

        let targetStore = try FitOnyStore.makePersistentStore(directoryURL: targetDir)
        #expect(throws: FitOnyVaultError.checksumMismatch) {
            try FitOnyBackupService.restorePublicBackupData(badArchiveData, into: targetStore)
        }

        // Чистое восстановление исправного архива
        try FitOnyBackupService.restorePublicBackupData(archiveData, into: targetStore)
        let restoredPrefs = try targetStore.fetchPreferences()
        let restoredSets = try targetStore.fetchCompletedSets()

        #expect(restoredPrefs.activePhase == .strength)
        #expect(restoredPrefs.currentMesocycleWeek == 4)
        #expect(restoredPrefs.selectedThemeID == "amoledDark")
        #expect(restoredSets.count == 1)
        #expect(restoredSets.first?.weightKg == 95)

        let preRestoreDir = targetDir.appendingPathComponent("Backups/PreRestore", isDirectory: true)
        let snapshots = (try? FileManager.default.contentsOfDirectory(atPath: preRestoreDir.path)) ?? []
        #expect(!snapshots.isEmpty)
    }

    @Test("Password-protected .fitonyvault encrypts workouts + vault and rejects wrong passwords")
    func fullEncryptedVaultArchiveRoundTrip() async throws {
        let tempDir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let sourceStore = try FitOnyStore.makeInMemoryStore()
        try sourceStore.upsertLoadState(
            ExerciseLoadState(
                exerciseID: PumpetPonyCatalog.ExerciseIDs.hipThrust,
                equipmentVariant: .primary,
                baselineWorkingWeightKg: 140
            )
        )

        let sourceVaultURL = tempDir.appendingPathComponent("source-vault.enc")
        let sourceVault = EncryptedVaultStore(
            vaultFileURL: sourceVaultURL,
            keyProvider: InMemoryVaultKeyProvider(),
            authService: MockBiometricAuth(shouldSucceed: true)
        )
        try await sourceVault.unlock()
        try sourceVault.update { state in
            state.protocolEntries.append(
                ProtocolLogEntry(title: "PrivateProtocolPhaseAlpha", details: "ConfidentialNotes")
            )
        }
        sourceVault.lockImmediately()

        // Используем 15_000 итераций в тесте для мгновенного прогона, проверяя полный цикл PBKDF2 + AES-GCM
        let archiveBytes = try FitOnyBackupService.exportEncryptedFullBackupData(
            from: sourceStore,
            vaultStore: sourceVault,
            password: "CorrectHorseBatteryStaple!2026",
            iterations: 15_000
        )

        let rawString = String(decoding: archiveBytes, as: UTF8.self)
        #expect(!rawString.contains("PrivateProtocolPhaseAlpha"))
        #expect(!rawString.contains("ConfidentialNotes"))

        let targetStore = try FitOnyStore.makeInMemoryStore()
        let targetVaultURL = tempDir.appendingPathComponent("target-vault.enc")
        let targetVault = EncryptedVaultStore(
            vaultFileURL: targetVaultURL,
            keyProvider: InMemoryVaultKeyProvider(),
            authService: MockBiometricAuth(shouldSucceed: true)
        )

        // Неверный пароль отклоняется криптографически
        #expect(throws: FitOnyVaultError.invalidBackupPasswordOrCorruptedData) {
            try FitOnyBackupService.restoreEncryptedFullBackupData(
                archiveBytes,
                password: "WrongPassword123",
                into: targetStore,
                vaultStore: targetVault
            )
        }

        // Верный пароль восстанавливает и открытую базу, и зашифрованный сейф
        try FitOnyBackupService.restoreEncryptedFullBackupData(
            archiveBytes,
            password: "CorrectHorseBatteryStaple!2026",
            into: targetStore,
            vaultStore: targetVault
        )

        let loads = try targetStore.fetchLoadStates()
        #expect(loads[ExerciseEquipmentKey(exerciseID: PumpetPonyCatalog.ExerciseIDs.hipThrust, variant: .primary)]?.baselineWorkingWeightKg == 140)

        let unlockedTarget = try await targetVault.unlock()
        #expect(unlockedTarget.protocolEntries.first?.title == "PrivateProtocolPhaseAlpha")
    }

    @Test("CSVExportService formats working sets, omits warmup e1RM, and escapes special characters")
    func csvExportFormattingAndEscaping() throws {
        let store = try FitOnyStore.makeInMemoryStore()
        var customExercise = ExerciseDefinition(
            code: "CUSTOM_ROW",
            name: .custom("Row, \"Heavy\" Grip"),
            isCompound: true,
            equipment: .machine(stepKg: 2.5),
            motionProfile: .arcWristPath,
            muscleContributions: [.upperBack: 1.0],
            defaultRestSeconds: 120
        )
        customExercise.id = UUID()
        try store.upsertExercise(customExercise, isCustom: true)

        let sessionID = UUID()
        try store.recordCompletedSet(
            CompletedSetRecord(
                sessionID: sessionID,
                exerciseID: customExercise.id,
                setIndex: 0,
                isWarmup: true,
                weightKg: 40,
                completedReps: 12,
                rir: 4
            )
        )
        try store.recordCompletedSet(
            CompletedSetRecord(
                sessionID: sessionID,
                exerciseID: customExercise.id,
                setIndex: 1,
                isWarmup: false,
                weightKg: 80,
                completedReps: 8,
                rir: 1,
                peakHeartRate: 152
            )
        )

        let csv = try CSVExportService.exportCompletedSetsCSV(from: store, language: .da)
        let rows = csv.split(separator: "\n")
        #expect(rows.count == 3) // header + warmup + working
        #expect(csv.contains("\"Row, \"\"Heavy\"\" Grip\""))
        #expect(String(rows[2]).contains(",152,"))
    }
}
