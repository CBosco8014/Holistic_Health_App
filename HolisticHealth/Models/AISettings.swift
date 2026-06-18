import Foundation

/// Per-million-token price metadata used to estimate cost when usage data is
/// available. Values are approximate and may be updated; cost is always shown as
/// an estimate, never a bill.
struct ModelPricing: Codable, Hashable {
    var inputPerMillion: Double
    var outputPerMillion: Double
}

/// User-selectable Gemini models for AI workflows.
enum GeminiModel: String, Codable, CaseIterable, Identifiable {
    case flash = "gemini-2.5-flash"
    case flashLite = "gemini-2.5-flash-lite"
    case pro = "gemini-2.5-pro"
    case flash2 = "gemini-2.0-flash"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flash: return "Gemini 2.5 Flash"
        case .flashLite: return "Gemini 2.5 Flash-Lite"
        case .pro: return "Gemini 2.5 Pro"
        case .flash2: return "Gemini 2.0 Flash"
        }
    }

    var blurb: String {
        switch self {
        case .flash: return "Fast and balanced — good default for most features."
        case .flashLite: return "Lowest cost, quickest — best for simple food parsing."
        case .pro: return "Highest quality — best for complex assessments."
        case .flash2: return "Previous-generation fast model."
        }
    }

    /// Approximate pricing (USD per 1M tokens). Used only for cost estimates.
    var pricing: ModelPricing {
        switch self {
        case .flash: return ModelPricing(inputPerMillion: 0.30, outputPerMillion: 2.50)
        case .flashLite: return ModelPricing(inputPerMillion: 0.10, outputPerMillion: 0.40)
        case .pro: return ModelPricing(inputPerMillion: 1.25, outputPerMillion: 10.0)
        case .flash2: return ModelPricing(inputPerMillion: 0.10, outputPerMillion: 0.40)
        }
    }
}

/// AI configuration that is safe to persist in plain storage. The API key is
/// NEVER stored here — it lives in the Keychain and is excluded from exports.
struct AISettings: Codable, Equatable {
    var selectedModel: GeminiModel
    /// Mirrors Keychain presence so the UI can show configured-state without
    /// reading the secret. Source of truth for the key remains the Keychain.
    var hasAPIKey: Bool

    init(selectedModel: GeminiModel = .flash, hasAPIKey: Bool = false) {
        self.selectedModel = selectedModel
        self.hasAPIKey = hasAPIKey
    }
}

/// The AI features that may consume Gemini.
enum AIFeature: String, Codable, CaseIterable, Identifiable {
    case foodParsing
    case photoAnalysis
    case menuVisualize
    case acneAssessment
    case consult
    case supplementSuggestion
    case lifestyleSuggestion
    case healthAssessment

    var id: String { rawValue }
}

/// A record of a single AI request, for usage and cost summaries. Never stores
/// the API key or raw prompt content.
struct APIUsageEvent: Codable, Identifiable, Hashable {
    var id: UUID
    var feature: AIFeature
    var model: String
    var timestamp: Date
    var success: Bool
    var promptTokens: Int?
    var completionTokens: Int?
    var totalTokens: Int?
    var estimatedCostUSD: Double?
    var errorMessage: String?

    init(
        id: UUID = UUID(),
        feature: AIFeature,
        model: String,
        timestamp: Date = Date(),
        success: Bool,
        promptTokens: Int? = nil,
        completionTokens: Int? = nil,
        totalTokens: Int? = nil,
        estimatedCostUSD: Double? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.feature = feature
        self.model = model
        self.timestamp = timestamp
        self.success = success
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
        self.estimatedCostUSD = estimatedCostUSD
        self.errorMessage = errorMessage
    }
}
