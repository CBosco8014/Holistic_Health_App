import Foundation

/// Failure modes the AI layer handles gracefully. Every feature should map these
/// to a calm, non-alarming message and a safe fallback (e.g. manual entry).
enum AIError: LocalizedError, Equatable {
    case missingAPIKey
    case modelUnavailable
    case rateLimited
    case requestFailed(status: Int)
    case malformedResponse
    case policyBlocked
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No Gemini API key is set. Add one in Settings → Gemini & Usage to use AI features. You can still enter foods manually."
        case .modelUnavailable:
            return "The selected Gemini model isn't available right now. Try another model in Settings."
        case .rateLimited:
            return "Gemini is rate-limited at the moment. Please wait a little and try again."
        case .requestFailed(let status):
            return "The AI request didn't succeed (code \(status)). You can try again or enter details manually."
        case .malformedResponse:
            return "The AI response couldn't be read. Please try again or enter details manually."
        case .policyBlocked:
            return "That request was blocked by safety policy. Try rephrasing, or continue manually."
        case .transport(let message):
            return "Couldn't reach Gemini (\(message)). Check your connection and try again."
        }
    }

    /// A short label suitable for logging in a usage event (no secrets).
    var logLabel: String {
        switch self {
        case .missingAPIKey: return "missing_api_key"
        case .modelUnavailable: return "model_unavailable"
        case .rateLimited: return "rate_limited"
        case .requestFailed(let s): return "request_failed_\(s)"
        case .malformedResponse: return "malformed_response"
        case .policyBlocked: return "policy_blocked"
        case .transport: return "transport_error"
        }
    }
}
