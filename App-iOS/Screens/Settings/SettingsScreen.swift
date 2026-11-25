import SwiftUI
import FitOnyCore

struct SettingsScreen: View {
    @Binding var selectedTheme: AppTheme
    @Environment(LanguageState.self) private var language

    var body: some View {
        @Bindable var bindableLanguage = language

        NavigationStack {
            Form {
                Section(language.text(FitOnyCopy.languageSection)) {
                    Picker(language.text(FitOnyCopy.languagePickerLabel), selection: $bindableLanguage.primaryLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.nativeDisplayName).tag(lang)
                        }
                    }

                    Toggle(
                        language.text(FitOnyCopy.bilingualHintToggle),
                        isOn: $bindableLanguage.showSecondaryRussianHint
                    )

                    Text(language.text(FitOnyCopy.quickSwitchHint))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(language.text(FitOnyCopy.appearanceSection)) {
                    Picker(language.text(FitOnyCopy.themePickerLabel), selection: $selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName(for: language.effectiveLanguage)).tag(theme)
                        }
                    }
                }
            }
            .navigationTitle(language.text(FitOnyCopy.tabSettings))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    LanguageQuickSwitchButton()
                }
            }
        }
    }
}
