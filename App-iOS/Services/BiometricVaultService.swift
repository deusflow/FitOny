import Foundation
import FitOnyCore

/// Проверка Face ID и расшифровка контейнера vault.enc (CryptoKit AES-GCM).
@MainActor
final class BiometricVaultService {
    private(set) var isUnlocked = false

    func lockImmediately() {
        isUnlocked = false
    }
}
