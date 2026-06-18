import SwiftUI

/// Lightweight placeholder used by US-001 to give every primary tab and Settings
/// a stable, navigable screen before real feature content is implemented in
/// later stories. The visual treatment here is intentionally plain; US-002
/// replaces these with the Ristoro design system.
struct PlaceholderScreen: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.secondary)
                    .padding(.top, 48)

                Text(title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    PlaceholderScreen(
        systemImage: "leaf",
        title: "Lifestyle",
        message: "Calm, data-reactive practices will live here."
    )
}
