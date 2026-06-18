import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PlaceholderScreen(
            systemImage: "gearshape",
            title: "Settings",
            message: "Gemini API key, model selection, usage costs, and privacy controls will live here."
        )
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
