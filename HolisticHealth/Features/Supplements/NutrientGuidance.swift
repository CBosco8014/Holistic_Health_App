import Foundation
import Combine

/// Decodable result for nutrient-area suggestions from Gemini.
struct NutrientSuggestionsResult: Decodable {
    struct Item: Decodable {
        var area: String
        var rationale: String
        var relevantInputs: [String]?
        var safetyNotes: String
        var clinicianQuestions: [String]?
    }
    var suggestions: [Item]
}

enum NutrientGuidanceSchema {
    static var schema: [String: Any] {
        let item = JSONSchema.object(properties: [
            "area": JSONSchema.string,
            "rationale": JSONSchema.string,
            "relevantInputs": JSONSchema.array(of: JSONSchema.string),
            "safetyNotes": JSONSchema.string,
            "clinicianQuestions": JSONSchema.array(of: JSONSchema.string)
        ], required: ["area", "rationale", "safetyNotes"])
        return JSONSchema.object(properties: ["suggestions": JSONSchema.array(of: item)], required: ["suggestions"])
    }
}

/// Produces careful, non-diagnostic nutrient-area suggestions based on the user's
/// goals, recent signals, and current supplements.
@MainActor
final class NutrientGuidanceViewModel: ObservableObject {
    typealias Suggester = (_ context: String) async throws -> NutrientSuggestionsResult

    @Published private(set) var suggestions: [NutrientSuggestion] = []
    @Published var isWorking = false
    @Published var errorMessage: String?

    private let suggester: Suggester
    private let contextProvider: () -> String

    init(suggester: @escaping Suggester, contextProvider: @escaping () -> String) {
        self.suggester = suggester
        self.contextProvider = contextProvider
    }

    convenience init(aiConfig: AIConfigStore, contextProvider: @escaping () -> String) {
        let service = GeminiService(config: aiConfig)
        self.init(suggester: { context in
            try await service.generate(
                feature: .supplementSuggestion,
                userText: "Based on this wellness context, suggest nutrient areas to consider (not a diagnosis):\n\(context)",
                schema: NutrientGuidanceSchema.schema,
                decoding: NutrientSuggestionsResult.self
            )
        }, contextProvider: contextProvider)
    }

    func generate() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let result = try await suggester(contextProvider())
            suggestions = result.suggestions.map {
                NutrientSuggestion(
                    area: $0.area,
                    rationale: $0.rationale,
                    relevantInputs: $0.relevantInputs ?? [],
                    safetyNotes: $0.safetyNotes,
                    clinicianQuestions: $0.clinicianQuestions ?? []
                )
            }
            if suggestions.isEmpty {
                errorMessage = "No suggestions were generated. Try again later."
            }
        } catch {
            errorMessage = (error as? AIError)?.errorDescription ?? error.localizedDescription
        }
    }
}
