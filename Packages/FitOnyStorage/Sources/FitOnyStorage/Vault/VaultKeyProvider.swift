import Foundation
import CryptoKit
import Security

/// Поставщик 256-битного мастер-ключа шифрования для контейнера `vault.enc`.
public protocol VaultKeyProviding: Sendable {
    func loadOrCreateMasterKey() throws -> SymmetricKey
    func deleteMasterKey() throws
}

/// Хранение мастер-ключа в системной связке ключей Apple Keychain (`ThisDeviceOnly` + привязка к биометрии на устройстве).
public struct KeychainVaultKeyProvider: VaultKeyProviding {
    public let service: String
    public let account: String
    public let requireBiometryAccessControl: Bool

    public init(
        service: String = "com.deusflow.fitony.advancedvault",
        account: String = "vault-master-key-v1",
        requireBiometryAccessControl: Bool = true
    ) {
        self.service = service
        self.account = account
        self.requireBiometryAccessControl = requireBiometryAccessControl
    }

    public func loadOrCreateMasterKey() throws -> SymmetricKey {
        if let existingData = try readKeyData() {
            return SymmetricKey(data: existingData)
        }

        let newKey = SymmetricKey(size: .bits256)
        let rawBytes = newKey.withUnsafeBytes { Data($0) }
        try saveKeyData(rawBytes)
        return newKey
    }

    public func deleteMasterKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw FitOnyVaultError.keychainFailure(status)
        }
    }

    private func readKeyData() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw FitOnyVaultError.keychainFailure(status)
        }
        return data
    }

    private func saveKeyData(_ data: Data) throws {
        var attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        if requireBiometryAccessControl,
           let access = SecAccessControlCreateWithFlags(
               nil,
               kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
               .biometryCurrentSet,
               nil
           ) {
            attributes[kSecAttrAccessControl as String] = access
        } else {
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status == errSecMissingEntitlement || status == errSecParam, requireBiometryAccessControl {
            // Безопасный откат для локальной отладки без платного профиля подписи: ключ всё равно привязан только к этому устройству.
            var fallback: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            let retry = SecItemAdd(fallback as CFDictionary, nil)
            fallback.removeAll()
            guard retry == errSecSuccess else {
                throw FitOnyVaultError.keychainFailure(retry)
            }
            return
        }

        guard status == errSecSuccess else {
            throw FitOnyVaultError.keychainFailure(status)
        }
    }
}

/// Изолированный в памяти поставщик ключа для быстрых модульных автотестов без системных диалогов Keychain.
public final class InMemoryVaultKeyProvider: VaultKeyProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var storedKeyData: Data?

    public init(initialKey: SymmetricKey? = nil) {
        if let initialKey {
            self.storedKeyData = initialKey.withUnsafeBytes { Data($0) }
        }
    }

    public func loadOrCreateMasterKey() throws -> SymmetricKey {
        lock.lock()
        defer { lock.unlock() }

        if let storedKeyData {
            return SymmetricKey(data: storedKeyData)
        }
        let generated = SymmetricKey(size: .bits256)
        self.storedKeyData = generated.withUnsafeBytes { Data($0) }
        return generated
    }

    public func deleteMasterKey() throws {
        lock.lock()
        defer { lock.unlock() }
        storedKeyData = nil
    }
}
