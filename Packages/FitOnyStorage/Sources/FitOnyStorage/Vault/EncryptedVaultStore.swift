import Foundation
import CryptoKit

/// Зашифрованное хранилище `vault.enc` на базе `AES.GCM` (256 бит) с мгновенной очисткой оперативной памяти при блокировке.
@MainActor
public final class EncryptedVaultStore {
    private static let authenticatedHeader = Data("FitOnyVault.v1".utf8)

    public let vaultFileURL: URL
    private let keyProvider: any VaultKeyProviding
    private let authService: any BiometricAuthenticating
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var unlockedPayload: VaultPayload?

    public var isUnlocked: Bool {
        unlockedPayload != nil
    }

    public init(
        vaultFileURL: URL? = nil,
        keyProvider: any VaultKeyProviding = KeychainVaultKeyProvider(),
        authService: any BiometricAuthenticating = BiometricAuthService()
    ) {
        if let vaultFileURL {
            self.vaultFileURL = vaultFileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.vaultFileURL = appSupport
                .appendingPathComponent("FitOny", isDirectory: true)
                .appendingPathComponent("vault.enc")
        }
        self.keyProvider = keyProvider
        self.authService = authService

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    /// Проверяет Face ID, загружает 256-битный ключ и расшифровывает `vault.enc` в оперативную память.
    @discardableResult
    public func unlock(localizedReason: String = "Разблокировать закрытый раздел Advanced Mode") async throws -> VaultPayload {
        try await authService.authenticate(reason: localizedReason)
        let key = try keyProvider.loadOrCreateMasterKey()
        let payload = try readAndDecryptFromDisk(using: key)
        self.unlockedPayload = payload
        return payload
    }

    /// Мгновенно стирает расшифрованные приватные структуры из оперативной памяти (при сворачивании приложения).
    public func lockImmediately() {
        unlockedPayload = nil
    }

    public func currentPayload() throws -> VaultPayload {
        guard let unlockedPayload else {
            throw FitOnyVaultError.vaultLocked
        }
        return unlockedPayload
    }

    /// Модифицирует данные открытого сейфа и атомарно перезаписывает зашифрованный `vault.enc`.
    @discardableResult
    public func update(_ mutate: (inout VaultPayload) -> Void) throws -> VaultPayload {
        guard var payload = unlockedPayload else {
            throw FitOnyVaultError.vaultLocked
        }
        mutate(&payload)
        payload.updatedAt = .now

        let key = try keyProvider.loadOrCreateMasterKey()
        try encryptAndWriteToDisk(payload, using: key)
        self.unlockedPayload = payload
        return payload
    }

    /// Полная замена содержимого сейфа (используется при восстановлении из парольного архива `.fitonyvault`).
    public func replaceVaultPayload(_ payload: VaultPayload) throws {
        let key = try keyProvider.loadOrCreateMasterKey()
        try encryptAndWriteToDisk(payload, using: key)
        if isUnlocked {
            self.unlockedPayload = payload
        }
    }

    /// Читает текущее содержимое сейфа напрямую ключом (когда пользователь уже прошёл проверку для создания бэкапа).
    internal func exportPayloadIfPresent() throws -> VaultPayload? {
        if let unlockedPayload {
            return unlockedPayload
        }
        guard FileManager.default.fileExists(atPath: vaultFileURL.path) else {
            return nil
        }
        let key = try keyProvider.loadOrCreateMasterKey()
        return try readAndDecryptFromDisk(using: key)
    }

    private func readAndDecryptFromDisk(using key: SymmetricKey) throws -> VaultPayload {
        guard FileManager.default.fileExists(atPath: vaultFileURL.path) else {
            let initial = VaultPayload()
            try encryptAndWriteToDisk(initial, using: key)
            return initial
        }

        let ciphertext = try Data(contentsOf: vaultFileURL)
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
            let plaintext = try AES.GCM.open(
                sealedBox,
                using: key,
                authenticating: Self.authenticatedHeader
            )
            return try decoder.decode(VaultPayload.self, from: plaintext)
        } catch {
            throw FitOnyVaultError.corruptedOrTamperedVaultFile
        }
    }

    private func encryptAndWriteToDisk(_ payload: VaultPayload, using key: SymmetricKey) throws {
        let directory = vaultFileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let plaintext = try encoder.encode(payload)
        let sealedBox = try AES.GCM.seal(
            plaintext,
            using: key,
            authenticating: Self.authenticatedHeader
        )
        guard let combined = sealedBox.combined else {
            throw FitOnyVaultError.corruptedOrTamperedVaultFile
        }

        #if os(iOS)
        let writeOptions: Data.WritingOptions = [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        #else
        let writeOptions: Data.WritingOptions = [.atomic]
        #endif
        try combined.write(to: vaultFileURL, options: writeOptions)

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = vaultFileURL
        try? mutableURL.setResourceValues(resourceValues)
    }
}
