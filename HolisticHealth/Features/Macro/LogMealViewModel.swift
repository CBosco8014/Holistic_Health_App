import Foundation
import Combine

/// Drives typed meal logging with **library-first** lookup: the local JSON macro
/// library is searched before any Gemini request. Known foods log directly;
/// unknown foods can request a Gemini estimate that requires confirmation before
/// being saved as a reusable record and a daily log entry.
@MainActor
final class LogMealViewModel: ObservableObject {
    /// Fetches a Gemini estimate for an unknown typed food. Injected for testing.
    typealias Estimator = (String) async throws -> ParsedFoodEstimate

    enum Step: Equatable { case search, confirmKnown, confirmEstimate }

    @Published var query = ""
    @Published private(set) var matches: [MacroLibraryRecord] = []
    @Published private(set) var step: Step = .search
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Editable confirmation fields (shared by known + estimate paths).
    @Published var draftName = ""
    @Published var draftServing = ""
    @Published var draftProtein = ""
    @Published var draftCarbs = ""
    @Published var draftFat = ""
    @Published var draftCalories = ""
    @Published var draftCategory: MealCategory = .snack
    @Published private(set) var draftConfidence: Double?
    @Published private(set) var draftAssumptions: String?

    private var selectedRecordID: UUID?

    private let library: MacroLibraryStore
    private let mealLog: MealLogStore
    private let estimator: Estimator

    init(library: MacroLibraryStore, mealLog: MealLogStore, estimator: @escaping Estimator) {
        self.library = library
        self.mealLog = mealLog
        self.estimator = estimator
    }

    /// Convenience initializer that wires the estimator to the real Gemini service.
    convenience init(library: MacroLibraryStore, mealLog: MealLogStore, aiConfig: AIConfigStore) {
        let service = GeminiService(config: aiConfig)
        self.init(library: library, mealLog: mealLog, estimator: { query in
            try await service.generate(
                feature: .foodParsing,
                userText: "Estimate macros for: \(query)",
                schema: FoodEstimateSchema.single,
                decoding: ParsedFoodEstimate.self
            )
        })
    }

    var hasMatches: Bool { !matches.isEmpty }

    var draftMacros: MacroNutrients {
        MacroNutrients(
            proteinGrams: Double(draftProtein) ?? 0,
            carbGrams: Double(draftCarbs) ?? 0,
            fatGrams: Double(draftFat) ?? 0,
            calories: Double(draftCalories) ?? 0
        )
    }

    /// Library-first: refresh matches from the local library (no network).
    func refreshMatches() {
        matches = query.nilIfBlank == nil ? [] : library.search(query)
    }

    /// Log a known library food directly (serving + category editable).
    func selectKnown(_ record: MacroLibraryRecord) {
        selectedRecordID = record.id
        draftName = record.canonicalName
        draftServing = record.servingDescription
        draftProtein = trimmed(record.macros.proteinGrams)
        draftCarbs = trimmed(record.macros.carbGrams)
        draftFat = trimmed(record.macros.fatGrams)
        draftCalories = trimmed(record.macros.calories)
        draftConfidence = nil
        draftAssumptions = nil
        step = .confirmKnown
    }

    /// Unknown food: request a Gemini estimate (only reached when the user opts in).
    func requestEstimate() async {
        guard query.nilIfBlank != nil else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let est = try await estimator(query)
            selectedRecordID = nil
            draftName = est.name
            draftServing = est.servingDescription
            draftProtein = trimmed(est.proteinGrams)
            draftCarbs = trimmed(est.carbGrams)
            draftFat = trimmed(est.fatGrams)
            draftCalories = trimmed(est.calories)
            draftConfidence = est.confidence
            draftAssumptions = est.assumptions
            step = .confirmEstimate
        } catch {
            errorMessage = (error as? AIError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Confirm + log. Estimate-sourced foods are also saved to the library as
    /// reusable, now-confirmed records.
    func confirmAndLog() {
        let name = draftName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        var libraryID = selectedRecordID
        if step == .confirmEstimate {
            let record = MacroLibraryRecord(
                canonicalName: name,
                servingDescription: draftServing,
                macros: draftMacros,
                source: .geminiText,
                confidence: draftConfidence,
                confirmation: .confirmed
            )
            library.upsert(record)
            libraryID = record.id
        }

        mealLog.add(MealLogEntry(
            libraryRecordID: libraryID,
            foodName: name,
            servingAmount: 1.0,
            servingDescription: draftServing,
            macros: draftMacros,
            category: draftCategory,
            source: step == .confirmEstimate ? .geminiText : .manual
        ))
        reset()
    }

    func cancelConfirm() {
        step = .search
        selectedRecordID = nil
    }

    func reset() {
        query = ""
        matches = []
        step = .search
        selectedRecordID = nil
        draftName = ""; draftServing = ""
        draftProtein = ""; draftCarbs = ""; draftFat = ""; draftCalories = ""
        draftConfidence = nil; draftAssumptions = nil
        draftCategory = .snack
    }

    private func trimmed(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
