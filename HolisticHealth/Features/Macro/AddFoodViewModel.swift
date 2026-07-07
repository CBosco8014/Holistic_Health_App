import Foundation
import Combine

/// Preset portion amounts offered as chips. `exact` == one full serving (100%).
enum PortionPreset: String, CaseIterable, Identifiable {
    case quarter, half, threeQuarter, exact, oneAndHalf, double
    var id: String { rawValue }

    var factor: Double {
        switch self {
        case .quarter: return 0.25
        case .half: return 0.5
        case .threeQuarter: return 0.75
        case .exact: return 1.0
        case .oneAndHalf: return 1.5
        case .double: return 2.0
        }
    }

    var label: String {
        switch self {
        case .quarter: return "25%"
        case .half: return "50%"
        case .threeQuarter: return "75%"
        case .exact: return "Exact"
        case .oneAndHalf: return "150%"
        case .double: return "Double"
        }
    }
}

/// Drives saved-food search and portion sizing. Changing the amount recalculates
/// macros (protein/carb/fat + secondary calories) before logging. No meal
/// planning in the MVP — only cancel or log now.
@MainActor
final class AddFoodViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var matches: [MacroLibraryRecord] = []
    @Published private(set) var selected: MacroLibraryRecord?
    @Published private(set) var factor: Double = 1.0
    @Published var customPercent: String = ""
    @Published var category: MealCategory = .snack

    private let library: MacroLibraryStore
    private let mealLog: MealLogStore

    init(library: MacroLibraryStore, mealLog: MealLogStore) {
        self.library = library
        self.mealLog = mealLog
    }

    var hasMatches: Bool { !matches.isEmpty }

    /// The multiplier actually used: a valid custom percent overrides the chip.
    var effectiveFactor: Double {
        if let pct = Double(customPercent), pct > 0 { return pct / 100 }
        return factor
    }

    /// Macros recalculated for the chosen amount.
    var scaledMacros: MacroNutrients {
        (selected?.macros ?? .zero).scaled(by: effectiveFactor)
    }

    func refresh() {
        matches = query.nilIfBlank == nil ? [] : library.search(query)
    }

    func select(_ record: MacroLibraryRecord) {
        selected = record
        factor = 1.0
        customPercent = ""
        category = .snack
    }

    func choosePreset(_ preset: PortionPreset) {
        factor = preset.factor
        customPercent = ""
    }

    func isPresetSelected(_ preset: PortionPreset) -> Bool {
        customPercent.isEmpty && abs(factor - preset.factor) < 0.0001
    }

    func clearSelection() {
        selected = nil
    }

    /// Logs the selected food at the current amount. Returns true on success.
    @discardableResult
    func log() -> Bool {
        guard let record = selected else { return false }
        mealLog.add(MealLogEntry(
            libraryRecordID: record.id,
            foodName: record.canonicalName,
            servingAmount: effectiveFactor,
            servingDescription: record.servingDescription,
            macros: scaledMacros,
            category: category,
            source: record.source
        ))
        clearSelection()
        return true
    }
}
