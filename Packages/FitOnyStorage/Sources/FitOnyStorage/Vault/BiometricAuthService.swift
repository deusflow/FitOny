import Foundation
import LocalAuthentication

/// Абстракция биометрической проверки личности (Face ID / Touch ID / код-пароль устройства).
public protocol BiometricAuthenticating: Sendable {
    func authenticate(reason: String) async throws
}

/// Системный сервис аутентификации через LocalAuthentication (`Face ID` с резервным кодом устройства).
public struct BiometricAuthService: BiometricAuthenticating {
    public init() {}

    public func authenticate(reason: String) async throws {
        let context = LAContext()
        var authError: NSError?

        let policy: LAPolicy
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            policy = .deviceOwnerAuthenticationWithBiometrics
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            policy = .deviceOwnerAuthentication
        } else {
            let message = authError?.localizedDescription ?? "No biometric or passcode policy configured."
            throw FitOnyVaultError.biometricsUnavailable(message)
        }

        do {
            let granted = try await context.evaluatePolicy(policy, localizedReason: reason)
            guard granted else {
                throw FitOnyVaultError.authenticationFailed
            }
        } catch is FitOnyVaultError {
            throw FitOnyVaultError.authenticationFailed
        } catch {
            throw FitOnyVaultError.authenticationFailed
        }
    }
}
