import Foundation

enum AppTheme: String, CaseIterable, Sendable, Codable {
    case fitOnyPink
    case neutralLight
    case amoledDark

    var displayName: String {
        switch self {
        case .fitOnyPink: "FitOny Pink"
        case .neutralLight: "Neutral"
        case .amoledDark: "AMOLED Dark"
        }
    }
}
