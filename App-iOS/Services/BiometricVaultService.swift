import Foundation
import Observation
import FitOnyCore
import FitOnyStorage

/// Координатор закрытого раздела Advanced Mode (Face ID + AES-GCM `vault.enc`) и резервных копий на iPhone.
@MainActor
@Observable
final class BiometricVaultService {
    private let vaultStore: EncryptedVaultStore

    private(set) var isUnlocked = false
    private(set) var payload: VaultPayload?
    private(set) var lastErrorMessage: String?

    init(vaultStore: EncryptedVaultStore = EncryptedVaultStore()) {
        self.vaultStore = vaultStore
    }

    func unlock(reason: String = "Подтвердите вход в закрытый раздел Advanced Mode") async {
        do {
            let loaded = try await vaultStore.unlock(localizedReason: reason)
            self.payload = loaded
            self.isUnlocked = true
            self.lastErrorMessage = nil
        } catch {
            self.lockImmediately()
            self.lastErrorMessage = error.localizedDescription
        }
    }

    /// Немедленно стирает расшифрованные структуры из памяти при сворачивании приложения в фон.
    func lockImmediately() {
        vaultStore.lockImmediately()
        payload = nil
        isUnlocked = false
    }

    func addBloodPressureReading(_ reading: BloodPressureReading) throws {
        let updated = try vaultStore.update { state in
            state.bloodPressureReadings.insert(reading, at: 0)
        }
        self.payload = updated
    }

    func addLabPanel(_ panel: LabPanelRecord) throws {
        let updated = try vaultStore.update { state in
            state.labPanels.insert(panel, at: 0)
        }
        self.payload = updated
    }

    func addProtocolEntry(_ entry: ProtocolLogEntry) throws {
        let updated = try vaultStore.update { state in
            state.protocolEntries.insert(entry, at: 0)
        }
        self.payload = updated
    }

    func addWellBeingCheck(_ check: WellBeingCheckRecord) throws {
        let updated = try vaultStore.update { state in
            state.wellBeingChecks.insert(check, at: 0)
        }
        self.payload = updated
    }

    // MARK: - One-Click Backups & Exports

    func exportPublicBackup(from store: FitOnyStore) throws -> Data {
        try FitOnyBackupService.exportPublicBackupData(from: store)
    }

    func restorePublicBackup(_ data: Data, into store: FitOnyStore) throws {
        try FitOnyBackupService.restorePublicBackupData(data, into: store)
    }

    func exportEncryptedFullBackup(from store: FitOnyStore, password: String) throws -> Data {
        try FitOnyBackupService.exportEncryptedFullBackupData(
            from: store,
            vaultStore: vaultStore,
            password: password
        )
    }

    func restoreEncryptedFullBackup(_ data: Data, password: String, into store: FitOnyStore) throws {
        try FitOnyBackupService.restoreEncryptedFullBackupData(
            data,
            password: password,
            into: store,
            vaultStore: vaultStore
        )
        if vaultStore.isUnlocked {
            self.payload = try? vaultStore.currentPayload()
        }
    }

    func exportSetsCSV(from store: FitOnyStore, language: AppLanguage) throws -> String {
        try CSVExportService.exportCompletedSetsCSV(from: store, language: language)
    }
}
