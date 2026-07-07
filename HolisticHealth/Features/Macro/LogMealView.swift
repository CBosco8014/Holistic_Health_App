import SwiftUI

/// Typed meal logging with library-first lookup (US-009). Searches saved foods
/// first; only offers a Gemini estimate when the user can't find a match, and
/// requires confirmation before saving an estimate.
struct LogMealView: View {
    @StateObject private var vm: LogMealViewModel
    @Environment(\.dismiss) private var dismiss

    init(library: MacroLibraryStore, mealLog: MealLogStore, aiConfig: AIConfigStore) {
        _vm = StateObject(wrappedValue: LogMealViewModel(library: library, mealLog: mealLog, aiConfig: aiConfig))
    }

    /// Test/preview seam.
    init(viewModel: LogMealViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                switch vm.step {
                case .search: searchStep
                case .confirmKnown, .confirmEstimate: confirmStep
                }
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Log Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Search

    private var searchStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Macro", title: "What did you eat?")

            DecoTextField(label: "Food", placeholder: "e.g. greek yogurt", text: $vm.query)
                .onChange(of: vm.query) { _, _ in vm.refreshMatches() }

            if vm.hasMatches {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    EyebrowText(text: "From your library")
                    ForEach(vm.matches) { record in
                        Button { vm.selectKnown(record) } label: {
                            libraryRow(record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else if vm.query.nilIfBlank != nil {
                Text("No saved match yet. You can ask Gemini for an estimate, or add it as a New Food.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            if vm.query.nilIfBlank != nil {
                Button {
                    Task { await vm.requestEstimate() }
                } label: {
                    HStack {
                        if vm.isLoading { ProgressView().tint(Theme.Colors.textOnInk) }
                        Text(vm.isLoading ? "Estimating…" : "Ask Gemini for an estimate")
                    }
                }
                .buttonStyle(.decoPrimary)
                .disabled(vm.isLoading)
            }

            if let error = vm.errorMessage {
                SafetyNote(text: error, systemImage: "exclamationmark.triangle")
            }
        }
    }

    private func libraryRow(_ record: MacroLibraryRecord) -> some View {
        FramedCard(padding: Theme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.canonicalName)
                        .font(Theme.Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("\(record.servingDescription) · P \(MacroFormat.grams(record.macros.proteinGrams)) · C \(MacroFormat.grams(record.macros.carbGrams)) · F \(MacroFormat.grams(record.macros.fatGrams))")
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

    // MARK: - Confirm

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            HStack {
                SectionHeader(eyebrow: "Confirm", title: vm.step == .confirmEstimate ? "Review estimate" : "Log food")
                Spacer()
                if vm.step == .confirmEstimate {
                    StatusTag(text: "Needs review", role: .warning)
                }
            }

            DecoTextField(label: "Food name", text: $vm.draftName)
            DecoTextField(label: "Serving", text: $vm.draftServing)

            HStack(spacing: Theme.Spacing.m) {
                DecoTextField(label: "Protein (g)", text: $vm.draftProtein, keyboard: .decimalPad)
                DecoTextField(label: "Carbs (g)", text: $vm.draftCarbs, keyboard: .decimalPad)
                DecoTextField(label: "Fat (g)", text: $vm.draftFat, keyboard: .decimalPad)
            }
            DecoTextField(label: "Calories (secondary)", text: $vm.draftCalories, keyboard: .decimalPad)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                EyebrowText(text: "Meal")
                FlowChips(items: MealCategory.allCases,
                          isSelected: { vm.draftCategory == $0 },
                          label: { $0.displayName },
                          toggle: { vm.draftCategory = $0 })
            }

            if vm.step == .confirmEstimate {
                if let confidence = vm.draftConfidence {
                    Text("Confidence: \(Int((confidence * 100).rounded()))%")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textFaint)
                }
                if let assumptions = vm.draftAssumptions, !assumptions.isEmpty {
                    Text("Assumptions: \(assumptions)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                SafetyNote(text: "Estimates are approximate. Edit anything before saving — confirmed foods are saved to your library for next time.")
            }

            HStack(spacing: Theme.Spacing.m) {
                Button("Back") { vm.cancelConfirm() }
                    .buttonStyle(.decoSecondary)
                Button(vm.step == .confirmEstimate ? "Save & Log" : "Log it") {
                    vm.confirmAndLog()
                    dismiss()
                }
                .buttonStyle(.decoPrimary)
            }
        }
    }
}
