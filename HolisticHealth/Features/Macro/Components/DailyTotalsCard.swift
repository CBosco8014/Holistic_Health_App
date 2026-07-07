import SwiftUI

/// Daily macro totals. Protein is the emphasized headline; carbs and fat follow.
/// Calories appear only as small secondary data. There is intentionally no
/// deficit, goal-gap, or weight-loss framing.
struct DailyTotalsCard: View {
    let totals: MacroNutrients
    var entryCount: Int

    var body: some View {
        InkPanel {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack {
                    EyebrowText(text: "Today", color: Theme.Colors.accentOnInk)
                    Spacer()
                    Text("\(entryCount) item\(entryCount == 1 ? "" : "s")")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textOnInkMuted)
                }

                HStack(alignment: .bottom, spacing: Theme.Spacing.s) {
                    MacroStat(value: totals.proteinGrams, label: "Protein",
                              emphasized: true, tint: Theme.Colors.accentOnInk)
                    Divider().frame(height: 44).overlay(Theme.Colors.accentOnInk.opacity(0.3))
                    MacroStat(value: totals.carbGrams, label: "Carbs", tint: Theme.Colors.textOnInk)
                    Divider().frame(height: 44).overlay(Theme.Colors.accentOnInk.opacity(0.3))
                    MacroStat(value: totals.fatGrams, label: "Fat", tint: Theme.Colors.textOnInk)
                }

                Text("Secondary: \(MacroFormat.calories(totals.calories))")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textOnInkMuted)
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        DailyTotalsCard(
            totals: MacroNutrients(proteinGrams: 96, carbGrams: 142, fatGrams: 54, calories: 1430),
            entryCount: 5
        )
        .padding()
    }
}
