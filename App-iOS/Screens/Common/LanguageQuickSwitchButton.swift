import SwiftUI
import FitOnyCore

/// Кнопка мгновенного переключения DA ⇄ RU в шапке экранов (тап — переключить, удержание — подсмотреть по-русски).
struct LanguageQuickSwitchButton: View {
    @Environment(LanguageState.self) private var language

    var body: some View {
        Button {
            language.toggle()
        } label: {
            HStack(spacing: 4) {
                Text("DA")
                    .fontWeight(language.effectiveLanguage == .da ? .bold : .regular)
                    .foregroundStyle(language.effectiveLanguage == .da ? .primary : .secondary)
                Text("/")
                    .foregroundStyle(.tertiary)
                Text("RU")
                    .fontWeight(language.effectiveLanguage == .ru ? .bold : .regular)
                    .foregroundStyle(language.effectiveLanguage == .ru ? .primary : .secondary)
            }
            .font(.caption.monospaced())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .onLongPressGesture(
            minimumDuration: 0.25,
            pressing: { isPressing in
                if language.primaryLanguage == .da {
                    language.isPeekingRussian = isPressing
                }
            },
            perform: {}
        )
        .accessibilityLabel(language.text(FitOnyCopy.languagePickerLabel))
    }
}
