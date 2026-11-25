import SwiftUI
import FitOnyCore

struct SettingsScreen: View {
    @Binding var selectedTheme: AppTheme

    var body: some View {
        NavigationStack {
            Form {
                Picker("Тема оформления", selection: $selectedTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
}
