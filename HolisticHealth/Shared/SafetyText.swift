import SwiftUI

/// Centralized wellness-only safety language. The product is framed as wellness
/// education and must never diagnose, treat, or cure. Reuse these strings rather
/// than re-writing disclaimers per screen.
enum SafetyText {
    static let onboarding =
        "This app offers wellness education inspired by naturopathic and functional-medicine ideas. It does not diagnose, treat, or cure any condition, and it isn't a substitute for care from a qualified professional."

    static let aiGeneral =
        "AI suggestions are wellness education only — not medical advice, diagnosis, or treatment. Always review changes with a qualified professional."

    static let acne =
        "This is a wellness reflection on inside-out patterns, not a diagnosis or treatment for acne. For persistent or severe skin concerns, please see a clinician."

    static let supplements =
        "Supplements can interact with medications and conditions, and aren't suitable for everyone (including during pregnancy). Review anything new with a qualified professional before starting."

    static let photoNotStored =
        "Photos are processed for analysis and are not stored by default."
}

/// A small, reusable disclaimer card.
struct SafetyNote: View {
    let text: String
    var systemImage: String = "leaf"

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.success)
            Text(text)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                .fill(Theme.Colors.success.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                .strokeBorder(Theme.Colors.success.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        SafetyNote(text: SafetyText.onboarding).padding()
    }
}
