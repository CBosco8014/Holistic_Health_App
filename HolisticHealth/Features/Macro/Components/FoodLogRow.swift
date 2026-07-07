import SwiftUI

/// A row in the Food Log. Shows the food name, time, serving amount + size,
/// the macro breakdown, secondary calories, and a remove action.
struct FoodLogRow: View {
    let entry: MealLogEntry
    let onRemove: () -> Void

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    private var servingText: String {
        let amount = entry.servingAmount
        let amountText = amount == 1 ? "" : (amount.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(amount))× "
            : String(format: "%.2g× ", amount))
        return amountText + entry.servingDescription
    }

    var body: some View {
        FramedCard(padding: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.foodName)
                        .font(Theme.Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Text(Self.timeFormatter.string(from: entry.loggedAt))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textFaint)
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.danger)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(entry.foodName)")
                }

                Text(servingText)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                HStack(spacing: Theme.Spacing.m) {
                    macroPill("P", entry.macros.proteinGrams, emphasized: true)
                    macroPill("C", entry.macros.carbGrams)
                    macroPill("F", entry.macros.fatGrams)
                    Spacer()
                    Text(MacroFormat.calories(entry.macros.calories))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textFaint)
                }
            }
        }
    }

    private func macroPill(_ letter: String, _ grams: Double, emphasized: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(letter)
                .font(Theme.Typography.poster(12))
                .foregroundStyle(emphasized ? Theme.Colors.accentText : Theme.Colors.textFaint)
            Text(MacroFormat.grams(grams))
                .font(emphasized ? Theme.Typography.sansBold(14) : Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}
