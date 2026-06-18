import SwiftUI

/// A 0–5 self-rating row used across check-ins (mood, energy, stress, etc.).
/// The value is optional so a measure can be left unlogged.
struct RatingSelector: View {
    let label: String
    @Binding var value: Int?
    var range: ClosedRange<Int> = 0...5

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                if value != nil {
                    Button("Clear") { value = nil }
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textFaint)
                }
            }
            HStack(spacing: 6) {
                ForEach(Array(range), id: \.self) { n in
                    Button {
                        value = n
                    } label: {
                        Text("\(n)")
                            .font(Theme.Typography.sansMedium(15))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .foregroundStyle(value == n ? Theme.Colors.textOnInk : Theme.Colors.textSecondary)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                                    .fill(value == n ? Theme.Colors.accent : Theme.Colors.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                                    .strokeBorder(Theme.Colors.goldLine, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var v: Int? = 3
    return ZStack {
        Theme.Colors.background.ignoresSafeArea()
        RatingSelector(label: "Stress", value: $v).padding()
    }
}
