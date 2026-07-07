import SwiftUI

/// A compact summary of a check-in for lists.
struct CheckInRow: View {
    let checkIn: HormoneSkinCheckIn

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private var summary: String {
        var parts: [String] = []
        if let phase = checkIn.cyclePhase, phase != .unknown { parts.append(phase.displayName) }
        if let acne = checkIn.acneSeverity { parts.append("Skin \(acne)/5") }
        if let stress = checkIn.stress { parts.append("Stress \(stress)/5") }
        if let mood = checkIn.mood { parts.append("Mood \(mood)/5") }
        return parts.isEmpty ? "Tap to view" : parts.joined(separator: " · ")
    }

    var body: some View {
        FramedCard(padding: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Self.dateFormatter.string(from: checkIn.date))
                        .font(Theme.Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(summary)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textFaint)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textFaint)
            }
        }
    }
}
