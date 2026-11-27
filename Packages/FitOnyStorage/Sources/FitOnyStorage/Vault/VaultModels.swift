import Foundation
import FitOnyCore

/// Ошибки криптоконтейнера Advanced Mode и системы резервного копирования.
public enum FitOnyVaultError: Error, LocalizedError, Sendable, Equatable {
    case vaultLocked
    case biometricsUnavailable(String)
    case authenticationFailed
    case keychainFailure(Int32)
    case corruptedOrTamperedVaultFile
    case unsupportedFormatVersion(Int)
    case checksumMismatch
    case emptyBackupPassword
    case invalidBackupPasswordOrCorruptedData
    case keyDerivationFailed(Int32)

    public var errorDescription: String? {
        switch self {
        case .vaultLocked:
            return "Advanced Mode vault is locked."
        case let .biometricsUnavailable(reason):
            return "Biometric authentication unavailable: \(reason)"
        case .authenticationFailed:
            return "Biometric authentication was cancelled or failed."
        case let .keychainFailure(status):
            return "Keychain operation failed with OSStatus \(status)."
        case .corruptedOrTamperedVaultFile:
            return "Vault ciphertext failed AES-GCM authentication check."
        case let .unsupportedFormatVersion(version):
            return "Unsupported archive format version: \(version)."
        case .checksumMismatch:
            return "Backup file integrity checksum mismatch."
        case .emptyBackupPassword:
            return "Backup password must not be empty."
        case .invalidBackupPasswordOrCorruptedData:
            return "Invalid backup password or corrupted archive."
        case let .keyDerivationFailed(status):
            return "PBKDF2 key derivation failed with status \(status)."
        }
    }
}

/// Замер артериального давления в BP Station (Advanced Mode).
public struct BloodPressureReading: Codable, Sendable, Equatable, Identifiable {
    public enum TimeOfDaySlot: String, Codable, Sendable, CaseIterable {
        case morningFasted
        case afternoon
        case evening
    }

    public var id: UUID
    public var recordedAt: Date
    public var systolicMMHg: Int
    public var diastolicMMHg: Int
    public var pulseBPM: Int?
    public var timeSlot: TimeOfDaySlot
    public var syncedToHealthKit: Bool
    public var note: String?

    /// Порог экстренного предупреждения (> 170/110 мм рт. ст. — риск при натуживании Вальсальвы).
    public var isHypertensiveCrisisAlert: Bool {
        systolicMMHg >= 170 || diastolicMMHg >= 110
    }

    public init(
        id: UUID = UUID(),
        recordedAt: Date = .now,
        systolicMMHg: Int,
        diastolicMMHg: Int,
        pulseBPM: Int? = nil,
        timeSlot: TimeOfDaySlot = .morningFasted,
        syncedToHealthKit: Bool = false,
        note: String? = nil
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.systolicMMHg = systolicMMHg
        self.diastolicMMHg = diastolicMMHg
        self.pulseBPM = pulseBPM
        self.timeSlot = timeSlot
        self.syncedToHealthKit = syncedToHealthKit
        self.note = note
    }
}

/// Отдельный биомаркер анализа крови с лабораторным референсным коридором.
public struct LabBiomarkerEntry: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var code: String
    public var name: String
    public var value: Double
    public var unit: String
    public var referenceMin: Double?
    public var referenceMax: Double?

    public var isOutOfRange: Bool {
        if let referenceMin, value < referenceMin { return true }
        if let referenceMax, value > referenceMax { return true }
        return false
    }

    public init(
        id: UUID = UUID(),
        code: String,
        name: String,
        value: Double,
        unit: String,
        referenceMin: Double? = nil,
        referenceMax: Double? = nil
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.value = value
        self.unit = unit
        self.referenceMin = referenceMin
        self.referenceMax = referenceMax
    }
}

/// Бланк сдачи анализов крови за конкретную дату.
public struct LabPanelRecord: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var sampledAt: Date
    public var laboratoryName: String
    public var markers: [LabBiomarkerEntry]
    public var notes: String?

    public init(
        id: UUID = UUID(),
        sampledAt: Date = .now,
        laboratoryName: String,
        markers: [LabBiomarkerEntry],
        notes: String? = nil
    ) {
        self.id = id
        self.sampledAt = sampledAt
        self.laboratoryName = laboratoryName
        self.markers = markers
        self.notes = notes
    }
}

/// Запись таймлайна фазы / протокола внутри закрытого раздела.
public struct ProtocolLogEntry: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var title: String
    public var startedAt: Date
    public var endedAt: Date?
    public var details: String

    public init(
        id: UUID = UUID(),
        title: String,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        details: String = ""
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.details = details
    }
}

/// Ежедневный индекс самочувствия закрытого раздела (WBI — Well-Being Index).
public struct WellBeingCheckRecord: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var recordedAt: Date
    public var moodScore: Int          // 1..5
    public var sleepQualityScore: Int  // 1..5
    public var appetiteScore: Int      // 1..5
    public var fluidRetentionScore: Int // 1..5 (1 = сухой, 5 = сильная задержка воды)

    public init(
        id: UUID = UUID(),
        recordedAt: Date = .now,
        moodScore: Int,
        sleepQualityScore: Int,
        appetiteScore: Int,
        fluidRetentionScore: Int
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.moodScore = min(5, max(1, moodScore))
        self.sleepQualityScore = min(5, max(1, sleepQualityScore))
        self.appetiteScore = min(5, max(1, appetiteScore))
        self.fluidRetentionScore = min(5, max(1, fluidRetentionScore))
    }
}

/// Корневая структура приватного контейнера `vault.enc` (никогда не попадает в открытый SQLite).
public struct VaultPayload: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var bloodPressureReadings: [BloodPressureReading]
    public var labPanels: [LabPanelRecord]
    public var protocolEntries: [ProtocolLogEntry]
    public var wellBeingChecks: [WellBeingCheckRecord]
    public var updatedAt: Date

    public init(
        schemaVersion: Int = 1,
        bloodPressureReadings: [BloodPressureReading] = [],
        labPanels: [LabPanelRecord] = [],
        protocolEntries: [ProtocolLogEntry] = [],
        wellBeingChecks: [WellBeingCheckRecord] = [],
        updatedAt: Date = .now
    ) {
        self.schemaVersion = schemaVersion
        self.bloodPressureReadings = bloodPressureReadings
        self.labPanels = labPanels
        self.protocolEntries = protocolEntries
        self.wellBeingChecks = wellBeingChecks
        self.updatedAt = updatedAt
    }
}
