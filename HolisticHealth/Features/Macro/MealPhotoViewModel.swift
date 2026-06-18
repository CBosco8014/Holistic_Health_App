import Foundation
import Combine

/// An editable food item shown in the meal-photo review step. Backed by string
/// fields so users can correct names, portions, and macros before accepting.
struct EditableFoodItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var serving: String
    var protein: String
    var carbs: String
    var fat: String
    var calories: String
    var confidence: Double?
    var notes: String?
    var category: MealCategory = .snack
    var include: Bool = true

    init(from estimate: ParsedFoodEstimate) {
        name = estimate.name
        serving = estimate.servingDescription
        protein = Self.fmt(estimate.proteinGrams)
        carbs = Self.fmt(estimate.carbGrams)
        fat = Self.fmt(estimate.fatGrams)
        calories = Self.fmt(estimate.calories)
        confidence = estimate.confidence
        notes = estimate.assumptions
    }

    var macros: MacroNutrients {
        MacroNutrients(
            proteinGrams: Double(protein) ?? 0,
            carbGrams: Double(carbs) ?? 0,
            fatGrams: Double(fat) ?? 0,
            calories: Double(calories) ?? 0
        )
    }

    private static func fmt(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

/// Drives meal photo / upload macro capture: image selection, Gemini analysis,
/// editable review, and confirm-to-save. Only confirmed items are written to the
/// daily log and the reusable library.
@MainActor
final class MealPhotoViewModel: ObservableObject {
    typealias Analyzer = (Data) async throws -> ParsedMealEstimate

    enum Phase: Equatable { case capture, review }

    @Published private(set) var imageData: Data?
    @Published private(set) var phase: Phase = .capture
    @Published var items: [EditableFoodItem] = []
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let library: MacroLibraryStore
    private let mealLog: MealLogStore
    private let analyzer: Analyzer

    init(library: MacroLibraryStore, mealLog: MealLogStore, analyzer: @escaping Analyzer) {
        self.library = library
        self.mealLog = mealLog
        self.analyzer = analyzer
    }

    convenience init(library: MacroLibraryStore, mealLog: MealLogStore, aiConfig: AIConfigStore) {
        let service = GeminiService(config: aiConfig)
        self.init(library: library, mealLog: mealLog, analyzer: { data in
            try await service.generate(
                feature: .photoAnalysis,
                userText: "Identify the foods in this meal photo and estimate per-item macros.",
                images: [data],
                schema: FoodEstimateSchema.meal,
                decoding: ParsedMealEstimate.self
            )
        })
    }

    var hasImage: Bool { imageData != nil }

    var includedTotals: MacroNutrients {
        items.filter(\.include).reduce(MacroNutrients.zero) { $0 + $1.macros }
    }

    func setImage(_ data: Data) {
        imageData = data
        items = []
        phase = .capture
        errorMessage = nil
    }

    func analyze() async {
        guard let data = imageData else { return }
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }
        do {
            let meal = try await analyzer(data)
            items = meal.items.map(EditableFoodItem.init)
            if items.isEmpty {
                errorMessage = "No foods were detected. Try another photo or enter the meal manually."
            } else {
                phase = .review
            }
        } catch {
            errorMessage = (error as? AIError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Saves only the included, confirmed items to the library and daily log.
    @discardableResult
    func confirm() -> Int {
        var saved = 0
        for item in items where item.include {
            let name = item.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            let record = MacroLibraryRecord(
                canonicalName: name,
                servingDescription: item.serving,
                macros: item.macros,
                source: .geminiPhoto,
                confidence: item.confidence,
                confirmation: .confirmed
            )
            library.upsert(record)
            mealLog.add(MealLogEntry(
                libraryRecordID: record.id,
                foodName: name,
                servingAmount: 1.0,
                servingDescription: item.serving,
                macros: item.macros,
                category: item.category,
                source: .geminiPhoto
            ))
            saved += 1
        }
        reset()
        return saved
    }

    func reset() {
        imageData = nil
        items = []
        phase = .capture
        errorMessage = nil
    }

    #if DEBUG
    /// Seeds a sample review state so the review UI can be screenshotted without
    /// a live Gemini call. No effect in release builds.
    func debugSeedReview() {
        items = [
            EditableFoodItem(from: ParsedFoodEstimate(name: "Salmon fillet", servingDescription: "150 g",
                proteinGrams: 34, carbGrams: 0, fatGrams: 12, calories: 280, confidence: 0.8, assumptions: "Baked")),
            EditableFoodItem(from: ParsedFoodEstimate(name: "Brown rice", servingDescription: "1 cup",
                proteinGrams: 5, carbGrams: 45, fatGrams: 2, calories: 220, confidence: 0.7, assumptions: nil))
        ]
        phase = .review
    }
    #endif
}
