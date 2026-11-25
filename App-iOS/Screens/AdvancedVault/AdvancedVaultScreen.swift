import SwiftUI
import FitOnyCore

struct AdvancedVaultScreen: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Закрытый раздел",
                systemImage: "lock.shield.fill",
                description: Text("Защищено Face ID и шифрованием AES-GCM: профиль, АД и биомаркеры")
            )
            .navigationTitle("Advanced")
        }
    }
}
