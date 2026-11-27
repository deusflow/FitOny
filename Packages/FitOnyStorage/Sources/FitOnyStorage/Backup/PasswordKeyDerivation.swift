import Foundation
import CryptoKit
import CommonCrypto

/// Вывод криптостойкого 256-битного ключа из пользовательского пароля резервной копии через `PBKDF2-HMAC-SHA256`.
public enum PasswordKeyDerivation {
    public static let defaultIterations: UInt32 = 210_000
    public static let saltByteCount = 32
    public static let derivedKeyByteCount = 32

    public static func generateRandomSalt(count: Int = saltByteCount) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        if status == errSecSuccess {
            return Data(bytes)
        }
        // Резервный генератор из CSPRNG системы при недоступности SecRandomCopyBytes
        var rng = SystemRandomNumberGenerator()
        return Data((0..<count).map { _ in UInt8.random(in: .min ... .max, using: &rng) })
    }

    public static func deriveSymmetricKey(
        password: String,
        salt: Data,
        iterations: UInt32 = defaultIterations
    ) throws -> SymmetricKey {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw FitOnyVaultError.emptyBackupPassword
        }

        let passwordBytes = Array(password.utf8)
        var derivedBytes = [UInt8](repeating: 0, count: derivedKeyByteCount)

        let status = salt.withUnsafeBytes { saltRawBuffer -> Int32 in
            guard let saltBase = saltRawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return Int32(kCCParamError)
            }
            return passwordBytes.withUnsafeBufferPointer { pwdBuffer -> Int32 in
                guard let pwdBase = pwdBuffer.baseAddress else {
                    return Int32(kCCParamError)
                }
                return CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    pwdBase,
                    pwdBuffer.count,
                    saltBase,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    iterations,
                    &derivedBytes,
                    derivedKeyByteCount
                )
            }
        }

        guard status == kCCSuccess else {
            throw FitOnyVaultError.keyDerivationFailed(status)
        }

        let key = SymmetricKey(data: Data(derivedBytes))
        derivedBytes.resetBytes(in: 0..<derivedBytes.count)
        return key
    }
}
