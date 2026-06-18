import SwiftUI

/// Applies the paper background to a screen, extending under the safe areas.
struct DecoBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.background.ignoresSafeArea())
    }
}

extension View {
    /// Standard Ristoro paper background for a screen.
    func decoBackground() -> some View { modifier(DecoBackground()) }
}

/// A section header: an eyebrow label, a title, and an ornamental rule — the
/// standard way sections are introduced across the app.
struct SectionHeader: View {
    let eyebrow: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            EyebrowText(text: eyebrow)
            Text(title)
                .font(Theme.Typography.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
            OrnamentalRule()
                .padding(.top, 2)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SectionHeader(eyebrow: "Macro", title: "Daily Totals")
            SectionHeader(eyebrow: "Lifestyle", title: "Suggested Practices")
        }
        .padding()
    }
    .decoBackground()
}
