import Foundation
import Combine

/// One adaptive consult step from Gemini: either the next question or a closing
/// summary.
struct ConsultStepResult: Decodable {
    var question: String?
    var isComplete: Bool?
    var summary: String?
}

enum ConsultSchema {
    static var schema: [String: Any] {
        JSONSchema.object(properties: [
            "question": JSONSchema.string,
            "isComplete": JSONSchema.boolean,
            "summary": JSONSchema.string
        ], required: [])
    }
}

/// Drives an adaptive consult: one question at a time, up to 10, across
/// digestion/stress/sleep/skin/cycle/food/supplements/hydration/lifestyle.
/// Logged patterns are only referenced when the user consents.
@MainActor
final class ConsultViewModel: ObservableObject {
    typealias NextStep = (_ history: [QAPair], _ context: String) async throws -> ConsultStepResult

    enum Phase: Equatable { case intro, asking, complete }

    let maxQuestions = 10

    @Published var phase: Phase = .intro
    @Published var usePatterns = false
    @Published private(set) var currentQuestion = ""
    @Published var currentAnswer = ""
    @Published private(set) var history: [QAPair] = []
    @Published private(set) var summary = ""
    @Published var isWorking = false
    @Published var errorMessage: String?

    private let nextStep: NextStep
    private let contextProvider: () -> String

    init(nextStep: @escaping NextStep, contextProvider: @escaping () -> String) {
        self.nextStep = nextStep
        self.contextProvider = contextProvider
    }

    convenience init(aiConfig: AIConfigStore, contextProvider: @escaping () -> String) {
        let service = GeminiService(config: aiConfig)
        self.init(nextStep: { history, context in
            let transcript = history.map { "Q: \($0.question)\nA: \($0.answer)" }.joined(separator: "\n")
            let prompt = """
            Conduct a gentle wellness consult. Ask the NEXT single question, or set isComplete=true with a brief summary if enough is known (max 10 questions).
            Context: \(context)
            So far:
            \(transcript.isEmpty ? "(no questions yet)" : transcript)
            """
            return try await service.generate(
                feature: .consult,
                userText: prompt,
                schema: ConsultSchema.schema,
                decoding: ConsultStepResult.self
            )
        }, contextProvider: contextProvider)
    }

    var progress: String { "\(history.count)/\(maxQuestions)" }

    func start() async {
        history = []
        summary = ""
        await fetchNext()
    }

    func submitAnswer() async {
        let answer = currentAnswer.nilIfBlank ?? "(skipped)"
        history.append(QAPair(question: currentQuestion, answer: answer))
        currentAnswer = ""
        if history.count >= maxQuestions {
            await complete(withSummary: nil)
        } else {
            await fetchNext()
        }
    }

    private func fetchNext() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let context = usePatterns ? contextProvider() : "Logged patterns not shared."
            let step = try await nextStep(history, context)
            if step.isComplete == true || (step.question?.nilIfBlank == nil) {
                await complete(withSummary: step.summary)
            } else {
                currentQuestion = step.question ?? ""
                phase = .asking
            }
        } catch {
            errorMessage = (error as? AIError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func complete(withSummary providedSummary: String?) async {
        if let providedSummary, providedSummary.nilIfBlank != nil {
            summary = providedSummary
        } else if summary.isEmpty {
            summary = "Thanks for reflecting. Notice any patterns across your answers, and bring anything notable to a professional."
        }
        phase = .complete
    }

    func buildSession() -> ConsultSession {
        ConsultSession(
            completedAt: Date(),
            topicAreas: ["digestion", "stress", "sleep", "skin", "cycle", "food", "supplements", "hydration", "lifestyle"],
            exchanges: history,
            usesLoggedPatterns: usePatterns,
            summary: summary
        )
    }
}
