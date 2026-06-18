import SwiftUI

/// Search saved foods and pick a portion (US-010). Meal photo capture is added
/// in US-011.
struct AddFoodView: View {
    @StateObject private var vm: AddFoodViewModel
    @Environment(\.dismiss) private var dismiss
    private let aiConfig: AIConfigStore
    private let library: MacroLibraryStore
    private let mealLog: MealLogStore

    init(library: MacroLibraryStore, mealLog: MealLogStore, aiConfig: AIConfigStore) {
        _vm = StateObject(wrappedValue: AddFoodViewModel(library: library, mealLog: mealLog))
        self.aiConfig = aiConfig
        self.library = library
        self.mealLog = mealLog
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                if let record = vm.selected {
                    portionStep(record)
                } else {
                    searchStep
                }
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Add Food")
        .navigationBarTitleDisplayMode(.inline)
        #if DEBUG
        .onAppear {
            // Debug-only: preselect a food so the portion step can be screenshotted.
            if let q = ProcessInfo.processInfo.environment["HH_PRESELECT"], vm.selected == nil {
                vm.query = q
                vm.refresh()
                if let first = vm.matches.first { vm.select(first) }
            }
        }
        #endif
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    if vm.selected != nil { vm.clearSelection() } else { dismiss() }
                }
            }
        }
    }

    // MARK: - Search

    private var searchStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Macro", title: "Add a saved food")

            // Meal photo capture (US-011) lives alongside saved-food search.
            NavigationLink {
                MealPhotoView(library: library, mealLog: mealLog, aiConfig: aiConfig)
            } label: {
                MacroActionTile(systemImage: "camera", title: "Capture a meal photo",
                                subtitle: "Estimate macros from a picture")
            }
            .buttonStyle(.plain)

            DecoTextField(label: "Search saved foods", placeholder: "e.g. chicken", text: $vm.query)
                .onChange(of: vm.query) { _, _ in vm.refresh() }

            if vm.hasMatches {
                ForEach(vm.matches) { record in
                    Button { vm.select(record) } label: { resultRow(record) }
                        .buttonStyle(.plain)
                }
            } else if vm.query.nilIfBlank != nil {
                Text("No saved foods match. Try Log Meal to add it with a Gemini estimate, or New Food to enter it manually.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            } else {
                Text("Search your growing food library, then choose how much you had.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    private func resultRow(_ record: MacroLibraryRecord) -> some View {
        FramedCard(padding: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.canonicalName)
                        .font(Theme.Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("\(record.servingDescription) · P \(MacroFormat.grams(record.macros.proteinGrams)) · C \(MacroFormat.grams(record.macros.carbGrams)) · F \(MacroFormat.grams(record.macros.fatGrams)) · \(MacroFormat.calories(record.macros.calories))")
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

    // MARK: - Portion

    private func portionStep(_ record: MacroLibraryRecord) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Portion", title: record.canonicalName)
            Text("Base serving: \(record.servingDescription)")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                EyebrowText(text: "Amount")
                FlowChips(items: PortionPreset.allCases,
                          isSelected: { vm.isPresetSelected($0) },
                          label: { $0.label },
                          toggle: { vm.choosePreset($0) })
                DecoTextField(label: "Custom %", placeholder: "e.g. 120", text: $vm.customPercent,
                              keyboard: .decimalPad)
            }

            // Live recalculation preview.
            FramedCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    EyebrowText(text: "For this amount")
                    HStack(spacing: Theme.Spacing.s) {
                        MacroStat(value: vm.scaledMacros.proteinGrams, label: "Protein",
                                  emphasized: true, tint: Theme.Colors.accentText)
                        MacroStat(value: vm.scaledMacros.carbGrams, label: "Carbs")
                        MacroStat(value: vm.scaledMacros.fatGrams, label: "Fat")
                    }
                    Text("Secondary: \(MacroFormat.calories(vm.scaledMacros.calories))")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textFaint)
                }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                EyebrowText(text: "Meal")
                FlowChips(items: MealCategory.allCases,
                          isSelected: { vm.category == $0 },
                          label: { $0.displayName },
                          toggle: { vm.category = $0 })
            }

            HStack(spacing: Theme.Spacing.m) {
                Button("Back") { vm.clearSelection() }
                    .buttonStyle(.decoSecondary)
                Button("Log it") {
                    vm.log()
                    dismiss()
                }
                .buttonStyle(.decoPrimary)
            }
        }
    }
}
