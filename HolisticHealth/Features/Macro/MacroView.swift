import SwiftUI

/// The Macro tab — a protein-forward macro tracker (NOT a calorie tracker).
/// Sections: Daily Totals, quick actions (Add Food, New Food, Log Meal,
/// Visualize Food), and the Food Log. Intentionally excludes calorie deficit,
/// burn rate, weight-loss countdowns, "Better Choices", and mood check sections.
struct MacroView: View {
    @EnvironmentObject private var mealLog: MealLogStore
    @EnvironmentObject private var library: MacroLibraryStore
    @EnvironmentObject private var aiConfig: AIConfigStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                DailyTotalsCard(totals: mealLog.dailyTotals(), entryCount: mealLog.entries().count)

                actionsSection
                foodLogSection
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Macro")
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Log", title: "Add to today")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.m) {
                NavigationLink {
                    LogMealView(library: library, mealLog: mealLog, aiConfig: aiConfig)
                } label: {
                    MacroActionTile(systemImage: "text.badge.plus", title: "Log Meal",
                                    subtitle: "Type what you ate")
                }
                NavigationLink { AddFoodView() } label: {
                    MacroActionTile(systemImage: "magnifyingglass", title: "Add Food",
                                    subtitle: "From saved foods")
                }
                NavigationLink { NewFoodView() } label: {
                    MacroActionTile(systemImage: "plus.square.on.square", title: "New Food",
                                    subtitle: "Enter macros")
                }
                NavigationLink { VisualizeFoodView() } label: {
                    MacroActionTile(systemImage: "wand.and.stars", title: "Visualize Food",
                                    subtitle: "Menu or dish")
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var foodLogSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Today", title: "Food Log")
            let todays = mealLog.entries()
            if todays.isEmpty {
                FramedCard {
                    VStack(spacing: Theme.Spacing.s) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(Theme.Colors.accentText)
                        Text("Nothing logged yet")
                            .font(Theme.Typography.bodyMedium)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("Use Log Meal or New Food to start tracking protein, carbs, and fat.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textFaint)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(todays) { entry in
                    FoodLogRow(entry: entry) { mealLog.remove(entry) }
                }
            }
        }
    }
}

/// A square quick-action tile for the Macro grid.
struct MacroActionTile: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        FramedCard(padding: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Theme.Colors.accentText)
                Text(title)
                    .font(Theme.Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textFaint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 84, alignment: .top)
        }
    }
}

#Preview {
    NavigationStack { MacroView() }
        .environmentObject(MealLogStore())
        .environmentObject(MacroLibraryStore())
}
