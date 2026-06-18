import Foundation
import Combine

/// Drives the Visualize Food workflow. Three input paths — menu photo, menu
/// screenshot upload, or typed dish description — all converge on a single
/// confirmation flow: Gemini generates a visual description + macro estimate,
/// which the user confirms/edits before logging and saving. No restaurant
/// recommendations, "Better Choices", deficit, or weight-loss framing.
@MainActor
final class VisualizeFoodViewModel: ObservableObject {
    typealias Visualizer = (_ text: String, _ image: Data?) async throws -> VisualizedFoodEstimate

    enum Step: Equatable { case input, confirm }

    @Published var dishText = ""
    @Published private(set) var imageData: Data?
    @Published private(set) var step: Step = .input
    @Published var isWorking = false
    @Published var errorMessage: String?

    // Confirmation fields.
    @Published private(set) var visualDescription = ""
    @Published var draftName = ""
    @Published var draftServing = ""
    @Published var draftProtein = ""
    @Published var draftCarbs = ""
    @Published var draftFat = ""
    @Published var draftCalories = ""
    @Published var draftCategory: MealCategory = .snack
    @Published private(set) var draftConfidence: Double?
    @Published private(set) var draftAssumptions: String?

    private let library: MacroLibraryStore
    private let mealLog: MealLogStore
    private let visualizer: Visualizer

    init(library: MacroLibraryStore, mealLog: MealLogStore, visualizer: @escaping Visualizer) {
        self.library = library
        self.mealLog = mealLog
        self.visualizer = visualizer
    }

    convenience init(library: MacroLibraryStore, mealLog: MealLogStore, aiConfig: AIConfigStore) {
        let service = GeminiService(config: aiConfig)
        self.init(library: library, mealLog: mealLog, visualizer: { text, image in
            let prompt = image == nil
                ? "Visualize and estimate macros for this dish: \(text)"
                : "Visualize and estimate macros for the menu item in this image." + (text.isEmpty ? "" : " Context: \(text)")
            return try await service.generate(
                feature: .menuVisualize,
                userText: prompt,
                images: image.map { [$0] } ?? [],
                schema: FoodEstimateSchema.visualize,
                decoding: VisualizedFoodEstimate.self
            )
        })
    }

    var canVisualize: Bool {
        dishText.nilIfBlank != nil || imageData != nil
    }

    var draftMacros: MacroNutrients {
        MacroNutrients(
            proteinGrams: Double(draftProtein) ?? 0,
            carbGrams: Double(draftCarbs) ?? 0,
            fatGrams: Double(draftFat) ?? 0,
            calories: Double(draftCalories) ?? 0
        )
    }

    func setImage(_ data: Data) {
        imageData = data
        errorMessage = nil
    }

    func clearImage() { imageData = nil }

    /// Single entry point used by all three input paths.
    func visualize() async {
        guard canVisualize else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let est = try await visualizer(dishText, imageData)
            visualDescription = est.visualDescription
            draftName = est.name
            draftServing = est.servingDescription
            draftProtein = fmt(est.proteinGrams)
            draftCarbs = fmt(est.carbGrams)
            draftFat = fmt(est.fatGrams)
            draftCalories = fmt(est.calories)
            draftConfidence = est.confidence
            draftAssumptions = est.assumptions
            step = .confirm
        } catch {
            errorMessage = (error as? AIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func confirmAndLog() {
        let name = draftName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let record = MacroLibraryRecord(
            canonicalName: name,
            servingDescription: draftServing,
            macros: draftMacros,
            source: .geminiMenu,
            confidence: draftConfidence,
            confirmation: .confirmed
        )
        library.upsert(record)
        mealLog.add(MealLogEntry(
            libraryRecordID: record.id,
            foodName: name,
            servingAmount: 1.0,
            servingDescription: draftServing,
            macros: draftMacros,
            category: draftCategory,
            source: .geminiMenu
        ))
        reset()
    }

    func backToInput() { step = .input }

    func reset() {
        dishText = ""
        imageData = nil
        step = .input
        visualDescription = ""
        draftName = ""; draftServing = ""
        draftProtein = ""; draftCarbs = ""; draftFat = ""; draftCalories = ""
        draftConfidence = nil; draftAssumptions = nil
        draftCategory = .snack
        errorMessage = nil
    }

    private func fmt(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
