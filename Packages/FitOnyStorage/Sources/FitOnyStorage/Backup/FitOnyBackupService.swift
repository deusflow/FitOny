import Foundation
import CryptoKit
import FitOnyCore

/// Конверт открытого бэкапа тренировок `.fitony` с проверкой целостности `SHA-256`.
public struct FitOnyPublicArchiveEnvelope: Codable, Sendable, Equatable {
    public static let currentFormatVersion = 1

    public var formatVersion: Int
    public var createdAt: Date
    public var sha256Hex: String
    public var payloadData: Data

    public init(
        formatVersion: Int = Self.currentFormatVersion,
        createdAt: Date = .now,
        sha256Hex: String,
        payloadData: Data
    ) {
        self.formatVersion = formatVersion
        self.createdAt = createdAt
        self.sha256Hex = sha256Hex
        self.payloadData = payloadData
    }
}

/// Конверт полного парольного архива `.fitonyvault` (`PBKDF2-HMAC-SHA256` + `AES.GCM`).
public struct FitOnyEncryptedVaultArchiveEnvelope: Codable, Sendable, Equatable {
    public static let currentFormatVersion = 1

    public var formatVersion: Int
    public var createdAt: Date
    public var pbkdf2Iterations: UInt32
    public var salt: Data
    public var ciphertext: Data

    public init(
        formatVersion: Int = Self.currentFormatVersion,
        createdAt: Date = .now,
        pbkdf2Iterations: UInt32,
        salt: Data,
        ciphertext: Data
    ) {
        self.formatVersion = formatVersion
        self.createdAt = createdAt
        self.pbkdf2Iterations = pbkdf2Iterations
        self.salt = salt
        self.ciphertext = ciphertext
    }
}

private struct CombinedVaultBackupPayload: Codable, Sendable {
    var publicBackup: FitOnyPublicBackupPayload
    var vaultPayload: VaultPayload
}

/// Сервис резервного копирования и восстановления в 1 нажатие (`.fitony` и парольный `.fitonyvault`).
@MainActor
public enum FitOnyBackupService {
    public static let publicBackupExtension = "fitony"
    public static let encryptedVaultBackupExtension = "fitonyvault"
    private static let fullBackupAAD = Data("FitOnyVaultBackup.v1".utf8)

    private static var encoder: JSONEncoder {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.sortedKeys]
        return enc
    }

    private static var decoder: JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }

    // MARK: - .fitony (Открытый контур тренировок)

    public static func exportPublicBackupData(from store: FitOnyStore) throws -> Data {
        let payload = try store.exportPublicBackupPayload()
        let payloadBytes = try encoder.encode(payload)
        let checksum = sha256HexString(for: payloadBytes)

        let envelope = FitOnyPublicArchiveEnvelope(
            formatVersion: FitOnyPublicArchiveEnvelope.currentFormatVersion,
            createdAt: .now,
            sha256Hex: checksum,
            payloadData: payloadBytes
        )
        return try encoder.encode(envelope)
    }

    public static func writePublicBackupFile(from store: FitOnyStore, to destinationURL: URL) throws {
        let data = try exportPublicBackupData(from: store)
        try data.write(to: destinationURL, options: [.atomic])
    }

    public static func restorePublicBackupData(_ archiveData: Data, into store: FitOnyStore) throws {
        let envelope = try decoder.decode(FitOnyPublicArchiveEnvelope.self, from: archiveData)
        guard envelope.formatVersion == FitOnyPublicArchiveEnvelope.currentFormatVersion else {
            throw FitOnyVaultError.unsupportedFormatVersion(envelope.formatVersion)
        }

        let computedHash = sha256HexString(for: envelope.payloadData)
        guard computedHash == envelope.sha256Hex else {
            throw FitOnyVaultError.checksumMismatch
        }

        let payload = try decoder.decode(FitOnyPublicBackupPayload.self, from: envelope.payloadData)
        try store.restorePublicBackupPayload(payload)
    }

    // MARK: - .fitonyvault (Полный архив включая закрытый раздел под паролем)

    public static func exportEncryptedFullBackupData(
        from store: FitOnyStore,
        vaultStore: EncryptedVaultStore,
        password: String,
        iterations: UInt32 = PasswordKeyDerivation.defaultIterations
    ) throws -> Data {
        let publicPayload = try store.exportPublicBackupPayload()
        let vaultPayload = try vaultStore.exportPayloadIfPresent() ?? VaultPayload()
        let combined = CombinedVaultBackupPayload(
            publicBackup: publicPayload,
            vaultPayload: vaultPayload
        )

        let plaintext = try encoder.encode(combined)
        let salt = PasswordKeyDerivation.generateRandomSalt()
        let derivedKey = try PasswordKeyDerivation.deriveSymmetricKey(
            password: password,
            salt: salt,
            iterations: iterations
        )

        let sealed = try AES.GCM.seal(
            plaintext,
            using: derivedKey,
            authenticating: fullBackupAAD
        )
        guard let combinedCiphertext = sealed.combined else {
            throw FitOnyVaultError.corruptedOrTamperedVaultFile
        }

        let envelope = FitOnyEncryptedVaultArchiveEnvelope(
            formatVersion: FitOnyEncryptedVaultArchiveEnvelope.currentFormatVersion,
            createdAt: .now,
            pbkdf2Iterations: iterations,
            salt: salt,
            ciphertext: combinedCiphertext
        )
        return try encoder.encode(envelope)
    }

    public static func writeEncryptedFullBackupFile(
        from store: FitOnyStore,
        vaultStore: EncryptedVaultStore,
        password: String,
        to destinationURL: URL,
        iterations: UInt32 = PasswordKeyDerivation.defaultIterations
    ) throws {
        let data = try exportEncryptedFullBackupData(
            from: store,
            vaultStore: vaultStore,
            password: password,
            iterations: iterations
        )
        try data.write(to: destinationURL, options: [.atomic])
    }

    public static func restoreEncryptedFullBackupData(
        _ archiveData: Data,
        password: String,
        into store: FitOnyStore,
        vaultStore: EncryptedVaultStore
    ) throws {
        let envelope = try decoder.decode(FitOnyEncryptedVaultArchiveEnvelope.self, from: archiveData)
        guard envelope.formatVersion == FitOnyEncryptedVaultArchiveEnvelope.currentFormatVersion else {
            throw FitOnyVaultError.unsupportedFormatVersion(envelope.formatVersion)
        }

        let derivedKey = try PasswordKeyDerivation.deriveSymmetricKey(
            password: password,
            salt: envelope.salt,
            iterations: envelope.pbkdf2Iterations
        )

        let plaintext: Data
        do {
            let box = try AES.GCM.SealedBox(combined: envelope.ciphertext)
            plaintext = try AES.GCM.open(
                box,
                using: derivedKey,
                authenticating: fullBackupAAD
            )
        } catch {
            throw FitOnyVaultError.invalidBackupPasswordOrCorruptedData
        }

        let combined = try decoder.decode(CombinedVaultBackupPayload.self, from: plaintext)
        try store.restorePublicBackupPayload(combined.publicBackup)
        try vaultStore.replaceVaultPayload(combined.vaultPayload)
    }

    private static func sha256HexString(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
