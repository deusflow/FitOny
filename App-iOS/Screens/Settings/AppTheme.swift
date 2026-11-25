import SwiftUI
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

    var tokens: ThemeTokens {
        switch self {
        case .fitOnyPink:
            // Neo-Pop палитра, снятая напрямую с фирменного логотипа GYM FITONY APP:
            // пастельно-розовый фон, сливочно-кремовые карточки, градиент ягода->коралл, мятно-бирюзовый акцент и тёмно-сливовый контур.
            return ThemeTokens(
                canvasBackground: Color(red: 0.99, green: 0.94, blue: 0.95),      // #FCF0F3
                heroBannerBackground: Color(red: 0.95, green: 0.70, blue: 0.76),  // #F2B2C2 (фон логотипа)
                cardSurface: Color(red: 1.00, green: 0.99, blue: 0.97),           // #FFFDF8 (тёплый кремовый)
                inkBorder: Color(red: 0.22, green: 0.09, blue: 0.13),             // #381722 (фирменный контур)
                subtleBorder: Color(red: 0.89, green: 0.75, blue: 0.79),          // #E3BFC9
                primaryAccent: Color(red: 0.86, green: 0.30, blue: 0.47),         // #DC4D79 (верх букв GYM)
                secondaryCoral: Color(red: 0.91, green: 0.42, blue: 0.39),        // #E96A64 (низ букв FITONY)
                mintHighlight: Color(red: 0.33, green: 0.65, blue: 0.57),         // #54A692 (мятный круг логотипа, читаемый контраст)
                primaryText: Color(red: 0.14, green: 0.08, blue: 0.10),           // #24141A
                secondaryText: Color(red: 0.42, green: 0.31, blue: 0.35),         // #6B4F59
                usesBoldComicBorders: true
            )

        case .neutralLight:
            return ThemeTokens(
                canvasBackground: Color(red: 0.96, green: 0.97, blue: 0.98),      // #F6F7F9
                heroBannerBackground: Color(red: 0.91, green: 0.93, blue: 0.96),
                cardSurface: .white,
                inkBorder: Color(red: 0.85, green: 0.87, blue: 0.90),
                subtleBorder: Color(red: 0.89, green: 0.91, blue: 0.93),
                primaryAccent: Color(red: 0.15, green: 0.39, blue: 0.92),         // #2563EB
                secondaryCoral: Color(red: 0.23, green: 0.51, blue: 0.96),
                mintHighlight: Color(red: 0.06, green: 0.60, blue: 0.50),
                primaryText: Color(red: 0.07, green: 0.09, blue: 0.15),
                secondaryText: Color(red: 0.39, green: 0.45, blue: 0.55),
                usesBoldComicBorders: false
            )

        case .amoledDark:
            // Ночная контрастная версия для зала с сохранением фирменных акцентов логотипа на чисто чёрном OLED.
            return ThemeTokens(
                canvasBackground: .black,                                         // #000000
                heroBannerBackground: Color(red: 0.13, green: 0.08, blue: 0.10),
                cardSurface: Color(red: 0.08, green: 0.07, blue: 0.09),           // #141217
                inkBorder: Color(red: 0.25, green: 0.18, blue: 0.22),
                subtleBorder: Color(red: 0.18, green: 0.15, blue: 0.18),
                primaryAccent: Color(red: 0.95, green: 0.37, blue: 0.55),         // #F25E8C
                secondaryCoral: Color(red: 0.96, green: 0.50, blue: 0.44),        // #F58070
                mintHighlight: Color(red: 0.55, green: 0.78, blue: 0.72),         // #8CC6B8 (оригинальный мятный)
                primaryText: Color(red: 0.98, green: 0.97, blue: 0.96),
                secondaryText: Color(red: 0.68, green: 0.63, blue: 0.66),
                usesBoldComicBorders: false
            )
        }
    }
}

struct ThemeTokens: Sendable {
    let canvasBackground: Color
    let heroBannerBackground: Color
    let cardSurface: Color
    let inkBorder: Color
    let subtleBorder: Color
    let primaryAccent: Color
    let secondaryCoral: Color
    let mintHighlight: Color
    let primaryText: Color
    let secondaryText: Color
    /// В фирменной теме FitOny Pink главные карточки и бейджи получают выразительный чёткий контур в духе логотипа.
    let usesBoldComicBorders: Bool

    var brandGradient: LinearGradient {
        LinearGradient(
            colors: [primaryAccent, secondaryCoral],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
