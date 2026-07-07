import Foundation
import Combine

/// Gemini result for a manual health assessment.
struct HealthAssessmentResult: Decodable {
    struct Ref: Decodable { var title: String; var url: String? }
    var patternSummary: String
    var possibleContributors: [String]?
    var currentFocusAreas: [String]?
    var activeTreatments: [String]?
    var holisticTreatments: [String]?
    var acnePhotoFindings: [String]?
    var caveats: String?
    var references: [Ref]?
}

enum HealthAssessmentSchema {
    static var schema: [String: Any] {
        let ref = JSONSchema.object(properties: ["title": JSONSchema.string, "url": JSONSchema.string],
                                    required: ["title"])
        return JSONSchema.object(properties: [
            "patternSummary": JSONSchema.string,
            "possibleContributors": JSONSchema.array(of: JSONSchema.string),
            "currentFocusAreas": JSONSchema.array(of: JSONSchema.string),
            "activeTreatments": JSONSchema.array(of: JSONSchema.string),
            "holisticTreatments": JSONSchema.array(of: JSONSchema.string),
            "acnePhotoFindings": JSONSchema.array(of: JSONSchema.string),
            "caveats": JSONSchema.string,
            "references": JSONSchema.array(of: ref)
        ], required: ["patternSummary"])
    }
}

/// Drives a manually initiated health assessment: pick data categories, generate
/// a gentle wellness reflection, edit it, and save.
@MainActor
final class HealthAssessmentViewModel: ObservableObject {
    typealias Generator = (_ categories: [AssessmentCategory], _ context: String) async throws -> HealthAssessmentResult

    enum Phase: Equatable { case setup, report }

    @Published var phase: Phase = .setup
    @Published var selectedCategories: Set<AssessmentCategory> = Set(AssessmentCategory.allCases)
    @Published private(set) var assessment: HealthAssessment?
    @Published var editedText = ""
    @Published var isWorking = false
    @Published var errorMessage: String?

    private let generator: Generator
    private let contextProvider: ([AssessmentCategory]) -> String

    init(generator: @escaping Generator, contextProvider: @escaping ([AssessmentCategory]) -> String) {
        self.generator = generator
        self.contextProvider = contextProvider
    }

    convenience init(aiConfig: AIConfigStore, contextProvider: @escaping ([AssessmentCategory]) -> String) {
        let service = GeminiService(config: aiConfig)
        self.init(generator: { categories, context in
            let names = categories.map(\.displayName).joined(separator: ", ")
            return try await service.generate(
                feature: .healthAssessment,
                userText: "Summarize wellness patterns across [\(names)].\nData:\n\(context)",
                schema: HealthAssessmentSchema.schema,
                decoding: HealthAssessmentResult.self
            )
        }, contextProvider: contextProvider)
    }

    func toggle(_ category: AssessmentCategory) {
        if selectedCategories.contains(category) { selectedCategories.remove(category) }
        else { selectedCategories.insert(category) }
    }

    var canGenerate: Bool { !selectedCategories.isEmpty }

    func generate() async {
        guard canGenerate else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        let categories = AssessmentCategory.allCases.filter { selectedCategories.contains($0) }
        do {
            let result = try await generator(categories, contextProvider(categories))
            let built = HealthAssessment(
                includedCategories: categories,
                patternSummary: result.patternSummary,
                possibleContributors: result.possibleContributors ?? [],
                currentFocusAreas: result.currentFocusAreas ?? [],
                activeTreatments: result.activeTreatments ?? [],
                holisticTreatments: result.holisticTreatments ?? [],
                acnePhotoFindings: result.acnePhotoFindings ?? [],
                references: (result.references ?? []).map { HealthReference(title: $0.title, url: $0.url) },
                caveats: result.caveats ?? SafetyText.aiGeneral
            )
            assessment = built
            editedText = built.patternSummary
            phase = .report
        } catch {
            errorMessage = (error as? AIError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Returns the assessment with the user's edits applied, ready to save.
    func finalizedAssessment() -> HealthAssessment? {
        guard var built = assessment else { return nil }
        if editedText.nilIfBlank != nil, editedText != built.patternSummary {
            built.editedReport = editedText
        }
        return built
    }
}
