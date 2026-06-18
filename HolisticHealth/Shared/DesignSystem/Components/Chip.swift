import SwiftUI

/// A tag / chip. Used for categories, filters, and selectable amount presets.
/// Supports a selected state with a gold fill.
struct Chip: View {
    let text: String
    var systemImage: String? = nil
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(Theme.Typography.sansMedium(13))
        }
        .foregroundStyle(isSelected ? Theme.Colors.textOnInk : Theme.Colors.accentText)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? Theme.Colors.accent : Theme.Colors.surface)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Theme.Colors.accent.opacity(isSelected ? 0 : 0.7), lineWidth: 1)
        )
    }
}

/// A small status pill (e.g. "Saved", "Needs review") tinted by role.
struct StatusTag: View {
    enum Role { case neutral, success, warning, danger }
    let text: String
    var role: Role = .neutral

    private var tint: Color {
        switch role {
        case .neutral: return Theme.Colors.accentText
        case .success: return Theme.Colors.success
        case .warning: return Theme.Palette.goldDeep
        case .danger: return Theme.Colors.danger
        }
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.Typography.poster(11))
            .tracking(1.5)
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.12)))
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        VStack(spacing: 14) {
            HStack {
                Chip(text: "Protein", isSelected: true)
                Chip(text: "Breakfast")
                Chip(text: "50%", systemImage: "scalemass")
            }
            HStack {
                StatusTag(text: "Saved", role: .success)
                StatusTag(text: "Needs review", role: .warning)
                StatusTag(text: "Error", role: .danger)
            }
        }
        .padding()
    }
}
