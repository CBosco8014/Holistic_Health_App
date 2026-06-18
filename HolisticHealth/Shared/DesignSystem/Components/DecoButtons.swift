import SwiftUI

/// Primary action button — solid gold-on-ink with a Deco feel.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.sansBold(16))
            .tracking(0.5)
            .foregroundStyle(Theme.Colors.textOnInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Palette.ink2, Theme.Palette.ink1],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .strokeBorder(Theme.Colors.accent, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Secondary action button — outlined gold on paper.
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.sansMedium(16))
            .foregroundStyle(Theme.Colors.accentText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .strokeBorder(Theme.Colors.accent, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var decoPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var decoSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        VStack(spacing: 16) {
            Button("Primary Action") {}.buttonStyle(.decoPrimary)
            Button("Secondary Action") {}.buttonStyle(.decoSecondary)
            Button("Disabled") {}.buttonStyle(.decoPrimary).disabled(true)
        }
        .padding()
    }
}
