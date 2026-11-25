import Foundation
import FitOnyCore

/// Координатор локального хранения (SwiftData + резервные копии).
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    private init() {}
}
