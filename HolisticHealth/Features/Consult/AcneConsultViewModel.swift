import Foundation
import Combine

/// Gemini result for an acne flare review. May request clarifying questions OR
/// return a wellness reflection (never a diagnosis or treatment).
struct AcneReviewResult: Decodable {
    struct Ref: Decodable { var title: String; var url: String? }
    var clarifyingQuestions: [String]?
    var summary: String
    var contextualFindings: [String]?
    var wellnessSuggestions: [String]?
    var references: [Ref]?
}

enum AcneReviewSchema {
    static var schema: [String: Any] {
        let ref = JSONSchema.object(properties: ["title": JSONSchema.string, "url": JSONSchema.string],
                                    required: ["title"])
        return JSONSchema.object(properties: [
            "clarifyingQuestions": JSONSchema.array(of: JSONSchema.string),
            "summary": JSONSchema.string,
            "contextualFindings": JSONSchema.array(of: JSONSchema.string),
            "wellnessSuggestions": JSONSchema.array(of: JSONSchema.string),
            "references": JSONSchema.array(of: ref)
        ], required: ["summary"])
    }
}

/// Drives the acne flare photo consult: consent → photo → optional clarifying
/// questions → wellness reflection → save (image never stored).
@MainActor
final class AcneConsultViewModel: ObservableObject {
    typealias Reviewer = (_ context: String, _ image: Data?) async throws -> AcneReviewResult

    enum Step: Equatable { case consent, capture, questions, result }

    @Published var step: Step = .consent
    @Published private(set) var imageData: Data?
    @Published var contextNote = ""
    @Published var answers: [QAPair] = []
    @Published private(set) var result: AcneReviewResult?
    @Published var isWorking = false
    @Published var errorMessage: String?

    private let reviewer: Reviewer

    init(reviewer: @escaping Reviewer) {
        self.reviewer = reviewer
    }

    convenience init(aiConfig: AIConfigStore) {
        let service = GeminiService(config: aiConfig)
        self.init(reviewer: { context, image in
            try await service.generate(
                feature: .acneAssessment,
                userText: "Acne flare wellness review. Context: \(context)",
                images: image.map { [$0] } ?? [],
                schema: AcneReviewSchema.schema,
                decoding: AcneReviewResult.self
            )
        })
    }

    var hasImage: Bool { imageData != nil }

    func grantConsentAndContinue() { step = .capture }

    func setImage(_ data: Data) { imageData = data; errorMessage = nil }

    /// First review pass — may surface clarifying questions.
    func review() async {
        await runReview(includeAnswers: false)
    }

    /// Second pass after the user answers clarifying questions.
    func submitAnswers() async {
        await runReview(includeAnswers: true)
    }

    private func runReview(includeAnswers: Bool) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let context = buildContext(includeAnswers: includeAnswers)
            let res = try await reviewer(context, imageData)
            result = res
            if let questions = res.clarifyingQuestions, !questions.isEmpty, !includeAnswers {
                answers = questions.map { QAPair(question: $0, answer: "") }
                step = .questions
            } else {
                step = .result
            }
        } catch {
            errorMessage = (error as? AIError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func buildContext(includeAnswers: Bool) -> String {
        var parts: [String] = []
        if let note = contextNote.nilIfBlank { parts.append("Notes: \(note)") }
        if includeAnswers {
            for qa in answers where qa.answer.nilIfBlank != nil {
                parts.append("\(qa.question) -> \(qa.answer)")
            }
        }
        return parts.isEmpty ? "No additional context provided." : parts.joined(separator: "\n")
    }

    /// Builds an AcneAssessment for saving. The source image is intentionally
    /// NOT included.
    func buildAssessment() -> AcneAssessment? {
        guard let result else { return nil }
        return AcneAssessment(
            summary: result.summary,
            userAnswers: answers.filter { $0.answer.nilIfBlank != nil },
            contextualFindings: result.contextualFindings ?? [],
            references: (result.references ?? []).map { HealthReference(title: $0.title, url: $0.url) },
            wellnessSuggestions: result.wellnessSuggestions ?? []
        )
    }
}
