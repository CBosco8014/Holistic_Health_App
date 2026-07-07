import SwiftUI

/// Placeholder used for tabs whose full feature content arrives in later stories.
/// As of US-002 it renders using the Ristoro design system (framed card on
/// paper) so the shell already reflects the approved aesthetic.
struct PlaceholderScreen: View {
    let systemImage: String
    let title: String
    let message: String
    var eyebrow: String = "Coming soon"

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                FramedCard {
                    VStack(spacing: Theme.Spacing.m) {
                        Image(systemName: systemImage)
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(Theme.Colors.accentText)
                        EyebrowText(text: eyebrow)
                        Text(title)
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        OrnamentalRule()
                        Text(message)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(Theme.Spacing.l)
            .padding(.top, Theme.Spacing.xl)
        }
        .decoBackground()
    }
}

#Preview {
    NavigationStack {
        PlaceholderScreen(
            systemImage: "leaf",
            title: "Lifestyle",
            message: "Calm, data-reactive practices will live here."
        )
        .navigationTitle("Lifestyle")
    }
}
