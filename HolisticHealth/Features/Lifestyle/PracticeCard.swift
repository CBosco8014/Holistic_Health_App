import SwiftUI

/// A recommended practice with save / start / complete / skip actions and an
/// optional rating. Calm, encouraging tone — no pressure.
struct PracticeCard: View {
    let practice: LifestylePractice
    let todaysStatus: PracticeStatus?
    let onAction: (PracticeStatus, Int?) -> Void

    @State private var rating: Int?

    var body: some View {
        FramedCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack {
                    Image(systemName: practice.type.systemImage)
                        .foregroundStyle(Theme.Colors.accentText)
                    Text(practice.title)
                        .font(Theme.Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    if let minutes = practice.durationMinutes {
                        Text("\(minutes) min")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textFaint)
                    }
                }

                Text(practice.detail)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)

                if let status = todaysStatus {
                    StatusTag(text: statusLabel(status),
                              role: status == .completed ? .success : .neutral)
                }

                RatingSelector(label: "Rate it (optional)", value: $rating)

                HStack(spacing: Theme.Spacing.s) {
                    smallButton("Save") { onAction(.saved, rating) }
                    smallButton("Start") { onAction(.started, rating) }
                    smallButton("Skip") { onAction(.skipped, rating) }
                    Button("Complete") { onAction(.completed, rating) }
                        .buttonStyle(.decoPrimary)
                }
            }
        }
    }

    private func smallButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(Theme.Typography.sansMedium(13))
            .foregroundStyle(Theme.Colors.accentText)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(Capsule().fill(Theme.Colors.surface))
            .overlay(Capsule().strokeBorder(Theme.Colors.goldLine, lineWidth: 1))
    }

    private func statusLabel(_ status: PracticeStatus) -> String {
        switch status {
        case .saved: return "Saved today"
        case .started: return "Started today"
        case .completed: return "Completed today"
        case .skipped: return "Skipped today"
        }
    }
}
