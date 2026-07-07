import Foundation

/// Typed Gemini client. Every feature goes through `generate`, which:
/// - reads the selected model + API key from `AIConfigStore`,
/// - applies the wellness guardrail system instruction,
/// - requests structured JSON matching a response schema,
/// - records a usage event (success or failure) without exposing the key,
/// - maps transport/HTTP/safety/parse problems to `AIError` with safe fallbacks.
@MainActor
final class GeminiService {
    private let config: AIConfigStore
    private let http: HTTPClient
    private let baseURL: String

    init(
        config: AIConfigStore,
        http: HTTPClient = URLSessionHTTPClient(),
        baseURL: String = "https://generativelanguage.googleapis.com/v1beta/models"
    ) {
        self.config = config
        self.http = http
        self.baseURL = baseURL
    }

    /// Performs a structured generation and decodes the JSON into `T`.
    /// - Parameters:
    ///   - feature: which feature (drives the system instruction + usage label).
    ///   - userText: the user-facing prompt content.
    ///   - images: optional JPEG image payloads (e.g. meal/acne photos).
    ///   - schema: a `JSONSchema`-built response schema dictionary.
    func generate<T: Decodable>(
        feature: AIFeature,
        userText: String,
        images: [Data] = [],
        schema: [String: Any],
        decoding: T.Type = T.self
    ) async throws -> T {
        guard let key = config.apiKey() else {
            throw AIError.missingAPIKey   // no request made; nothing to log
        }
        let model = config.selectedModel

        let body = Self.requestBody(
            instruction: AIGuardrails.instruction(for: feature),
            userText: userText,
            images: images,
            schema: schema
        )

        guard let url = URL(string: "\(baseURL)/\(model.rawValue):generateContent?key=\(key)"),
              let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            throw AIError.malformedResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        // --- Transport ---
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await http.send(request)
        } catch {
            recordFailure(feature: feature, model: model, error: .transport(error.localizedDescription))
            throw AIError.transport(error.localizedDescription)
        }

        // --- HTTP status ---
        switch response.statusCode {
        case 200:
            break
        case 401, 403:
            let e = AIError.requestFailed(status: response.statusCode)
            recordFailure(feature: feature, model: model, error: e)
            throw e
        case 404:
            recordFailure(feature: feature, model: model, error: .modelUnavailable)
            throw AIError.modelUnavailable
        case 429:
            recordFailure(feature: feature, model: model, error: .rateLimited)
            throw AIError.rateLimited
        default:
            let e = AIError.requestFailed(status: response.statusCode)
            recordFailure(feature: feature, model: model, error: e)
            throw e
        }

        // --- Parse envelope ---
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            recordFailure(feature: feature, model: model, error: .malformedResponse)
            throw AIError.malformedResponse
        }

        // Safety / policy block detection.
        if Self.isBlocked(root) {
            recordFailure(feature: feature, model: model, error: .policyBlocked)
            throw AIError.policyBlocked
        }

        guard let jsonText = Self.extractText(root) else {
            recordFailure(feature: feature, model: model, error: .malformedResponse)
            throw AIError.malformedResponse
        }

        // --- Decode into T ---
        guard let payload = jsonText.data(using: .utf8),
              let value = try? JSONCoding.decoder.decode(T.self, from: payload) else {
            recordFailure(feature: feature, model: model, error: .malformedResponse)
            throw AIError.malformedResponse
        }

        // --- Usage + success event ---
        let usage = Self.usage(root)
        let cost = AIConfigStore.estimateCost(
            model: model,
            promptTokens: usage.prompt,
            completionTokens: usage.completion
        )
        config.record(APIUsageEvent(
            feature: feature,
            model: model.rawValue,
            success: true,
            promptTokens: usage.prompt,
            completionTokens: usage.completion,
            totalTokens: usage.total,
            estimatedCostUSD: cost
        ))
        return value
    }

    // MARK: - Request construction

    static func requestBody(instruction: String, userText: String, images: [Data], schema: [String: Any]) -> [String: Any] {
        var parts: [[String: Any]] = [["text": userText]]
        for image in images {
            parts.append([
                "inlineData": [
                    "mimeType": "image/jpeg",
                    "data": image.base64EncodedString()
                ]
            ])
        }
        return [
            "systemInstruction": ["parts": [["text": instruction]]],
            "contents": [["role": "user", "parts": parts]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": schema,
                "temperature": 0.4
            ]
        ]
    }

    // MARK: - Response parsing helpers

    static func isBlocked(_ root: [String: Any]) -> Bool {
        if let feedback = root["promptFeedback"] as? [String: Any],
           feedback["blockReason"] != nil {
            return true
        }
        if let candidates = root["candidates"] as? [[String: Any]],
           let first = candidates.first,
           let reason = first["finishReason"] as? String,
           reason == "SAFETY" || reason == "BLOCKLIST" || reason == "PROHIBITED_CONTENT" {
            return true
        }
        return false
    }

    static func extractText(_ root: [String: Any]) -> String? {
        guard let candidates = root["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            return nil
        }
        let text = parts.compactMap { $0["text"] as? String }.joined()
        return text.isEmpty ? nil : text
    }

    static func usage(_ root: [String: Any]) -> (prompt: Int?, completion: Int?, total: Int?) {
        guard let meta = root["usageMetadata"] as? [String: Any] else { return (nil, nil, nil) }
        return (
            meta["promptTokenCount"] as? Int,
            meta["candidatesTokenCount"] as? Int,
            meta["totalTokenCount"] as? Int
        )
    }

    // MARK: - Usage logging

    private func recordFailure(feature: AIFeature, model: GeminiModel, error: AIError) {
        config.record(APIUsageEvent(
            feature: feature,
            model: model.rawValue,
            success: false,
            errorMessage: error.logLabel
        ))
    }
}
