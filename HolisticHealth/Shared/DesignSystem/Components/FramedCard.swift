import SwiftUI

/// A framed card — the signature Ristoro container. A raised cream surface with
/// a thin gold inner frame, evoking the Art Deco "gold frame" motif from the
/// design guide.
struct FramedCard<Content: View>: View {
    var padding: CGFloat = Theme.Spacing.l
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Theme.Colors.goldLine, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card - 3, style: .continuous)
                    .strokeBorder(Theme.Colors.accent.opacity(0.25), lineWidth: 1)
                    .padding(3)
            )
            .shadow(color: Theme.Palette.ink1.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

/// An ink-surface variant for headers / hero panels (midnight navy with gold).
struct InkPanel<Content: View>: View {
    var padding: CGFloat = Theme.Spacing.l
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Palette.ink2, Theme.Palette.ink1, Theme.Palette.ink0],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Theme.Colors.accent.opacity(0.5), lineWidth: 1)
            )
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        VStack(spacing: 16) {
            FramedCard {
                VStack(alignment: .leading, spacing: 6) {
                    EyebrowText(text: "Today")
                    Text("Framed Card").font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("A raised cream surface with a gold inner frame.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            InkPanel {
                Text("Ink Panel")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.accentOnInk)
            }
        }
        .padding()
    }
}
