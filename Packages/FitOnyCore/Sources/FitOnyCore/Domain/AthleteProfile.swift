import Foundation

public enum PhysiologicalProfile: String, Codable, Sendable, CaseIterable {
    case natural
    case enhanced

    /// Минимальное окно восстановления для прямой нагрузки на мышечную группу (в часах).
    public var directMuscleRecoveryHours: Double {
        switch self {
        case .natural: 48.0
        case .enhanced: 36.0
        }
    }
}
