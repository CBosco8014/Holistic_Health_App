import SwiftUI

/// Manually create a food: enter macros, optionally save it to the reusable
/// library, and optionally log it to today. Protein/carbs/fat are primary;
/// calories are secondary.
struct NewFoodView: View {
    @EnvironmentObject private var library: MacroLibraryStore
    @EnvironmentObject private var mealLog: MealLogStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var serving = "1 serving"
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var calories = ""
    @State private var category: MealCategory = .snack
    @State private var saveToLibrary = true
    @State private var logToday = true

    private var macros: MacroNutrients {
        MacroNutrients(
            proteinGrams: Double(protein) ?? 0,
            carbGrams: Double(carbs) ?? 0,
            fatGrams: Double(fat) ?? 0,
            calories: Double(calories) ?? 0
        )
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (saveToLibrary || logToday)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                SectionHeader(eyebrow: "Macro", title: "New Food")

                DecoTextField(label: "Food name", placeholder: "e.g. Grilled chicken breast", text: $name)
                DecoTextField(label: "Serving size", placeholder: "e.g. 1 breast (120 g)", text: $serving)

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    EyebrowText(text: "Macros per serving")
                    HStack(spacing: Theme.Spacing.m) {
                        numberField("Protein (g)", $protein)
                        numberField("Carbs (g)", $carbs)
                        numberField("Fat (g)", $fat)
                    }
                    numberField("Calories (secondary)", $calories)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    EyebrowText(text: "Meal")
                    FlowChips(
                        items: MealCategory.allCases,
                        isSelected: { category == $0 },
                        label: { $0.displayName },
                        toggle: { category = $0 }
                    )
                }

                Toggle("Save to my food library", isOn: $saveToLibrary)
                    .font(Theme.Typography.body)
                    .tint(Theme.Colors.accent)
                Toggle("Log to today", isOn: $logToday)
                    .font(Theme.Typography.body)
                    .tint(Theme.Colors.accent)

                Button("Save") { save() }
                    .buttonStyle(.decoPrimary)
                    .disabled(!canSave)
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("New Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func numberField(_ label: String, _ binding: Binding<String>) -> some View {
        DecoTextField(label: label, placeholder: "0", text: binding, keyboard: .decimalPad)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        var libraryID: UUID? = nil

        if saveToLibrary {
            let record = MacroLibraryRecord(
                canonicalName: trimmedName,
                servingDescription: serving,
                macros: macros,
                source: .manual,
                confirmation: .confirmed
            )
            library.upsert(record)
            libraryID = record.id
        }

        if logToday {
            mealLog.add(MealLogEntry(
                libraryRecordID: libraryID,
                foodName: trimmedName,
                servingAmount: 1.0,
                servingDescription: serving,
                macros: macros,
                category: category,
                source: .manual
            ))
        }
        dismiss()
    }
}

#Preview {
    NavigationStack { NewFoodView() }
        .environmentObject(MacroLibraryStore())
        .environmentObject(MealLogStore())
}
