import Foundation
import FitOnyCore

enum AppTheme: String, CaseIterable, Sendable, Codable {
    case fitOnyPink
    case neutralLight
    case amoledDark

    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .fitOnyPink: "FitOny Pink"
        case .neutralLight: LocalizedCopy(da: "Neutral lys", ru: "Neutral").value(for: language)
        case .amoledDark: "AMOLED Dark"
        }
    }
}
