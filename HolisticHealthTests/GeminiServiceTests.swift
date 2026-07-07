import XCTest
@testable import HolisticHealth

private struct TestFood: Decodable, Equatable {
    let name: String
    let protein: Double
}

private final class MockHTTPClient: HTTPClient {
    var handler: (URLRequest) throws -> (Data, HTTPURLResponse)
    private(set) var lastRequest: URLRequest?

    init(handler: @escaping (URLRequest) throws -> (Data, HTTPURLResponse)) {
        self.handler = handler
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        return try handler(request)
    }
}

@MainActor
final class GeminiServiceTests: XCTestCase {

    private func makeConfig(withKey: Bool) -> AIConfigStore {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = AIConfigStore(persistence: FileDataStore(baseDirectory: dir),
                                  keychainAccount: "test_gem_\(UUID().uuidString)")
        if withKey { store.saveAPIKey("test-key-123") }
        return store
    }

    private func http(status: Int, json: Any) -> MockHTTPClient {
        let data = try! JSONSerialization.data(withJSONObject: json)
        return MockHTTPClient { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (data, resp)
        }
    }

    /// Builds a Gemini success envelope wrapping an inner JSON string.
    private func envelope(innerJSON: String, finishReason: String = "STOP") -> [String: Any] {
        [
            "candidates": [[
                "content": ["parts": [["text": innerJSON]]],
                "finishReason": finishReason
            ]],
            "usageMetadata": [
                "promptTokenCount": 100,
                "candidatesTokenCount": 50,
                "totalTokenCount": 150
            ]
        ]
    }

    private let schema = JSONSchema.object(
        properties: ["name": JSONSchema.string, "protein": JSONSchema.number],
        required: ["name", "protein"]
    )

    func testMissingKeyThrows() async {
        let config = makeConfig(withKey: false)
        let service = GeminiService(config: config, http: http(status: 200, json: [:]))
        do {
            _ = try await service.generate(feature: .foodParsing, userText: "eggs", schema: schema, decoding: TestFood.self)
            XCTFail("Expected missingAPIKey")
        } catch {
            XCTAssertEqual(error as? AIError, .missingAPIKey)
        }
        XCTAssertTrue(config.usageEvents.isEmpty, "No request -> no usage event")
    }

    func testRequestConstructionIncludesInstructionSchemaAndText() async throws {
        let config = makeConfig(withKey: true)
        let mock = http(status: 200, json: envelope(innerJSON: #"{"name":"Eggs","protein":12}"#))
        let service = GeminiService(config: config, http: mock)
        _ = try await service.generate(feature: .foodParsing, userText: "two eggs",
                                       images: [Data([0xFF, 0xD8])], schema: schema, decoding: TestFood.self)

        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: mock.lastRequest!.httpBody!) as? [String: Any])
        let sys = (body["systemInstruction"] as? [String: Any])?["parts"] as? [[String: Any]]
        XCTAssertTrue((sys?.first?["text"] as? String)?.contains("NEVER diagnose") ?? false)

        let gen = body["generationConfig"] as? [String: Any]
        XCTAssertEqual(gen?["responseMimeType"] as? String, "application/json")
        XCTAssertNotNil(gen?["responseSchema"])

        let contents = body["contents"] as? [[String: Any]]
        let parts = contents?.first?["parts"] as? [[String: Any]]
        XCTAssertEqual(parts?.first?["text"] as? String, "two eggs")
        XCTAssertNotNil(parts?.last?["inlineData"], "Image should be attached as inlineData")

        // The API key must be in the URL query, never in the JSON body.
        XCTAssertTrue(mock.lastRequest!.url!.query!.contains("key=test-key-123"))
        XCTAssertFalse(String(data: mock.lastRequest!.httpBody!, encoding: .utf8)!.contains("test-key-123"))
    }

    func testSuccessDecodesAndLogsUsage() async throws {
        let config = makeConfig(withKey: true)
        let service = GeminiService(config: config,
                                    http: http(status: 200, json: envelope(innerJSON: #"{"name":"Eggs","protein":12}"#)))
        let result = try await service.generate(feature: .foodParsing, userText: "eggs", schema: schema, decoding: TestFood.self)
        XCTAssertEqual(result, TestFood(name: "Eggs", protein: 12))

        XCTAssertEqual(config.usageEvents.count, 1)
        let event = config.usageEvents[0]
        XCTAssertTrue(event.success)
        XCTAssertEqual(event.totalTokens, 150)
        XCTAssertNotNil(event.estimatedCostUSD)
    }

    func testMalformedResponseThrowsAndLogsFailure() async {
        let config = makeConfig(withKey: true)
        let service = GeminiService(config: config,
                                    http: http(status: 200, json: envelope(innerJSON: "not json at all")))
        do {
            _ = try await service.generate(feature: .foodParsing, userText: "eggs", schema: schema, decoding: TestFood.self)
            XCTFail("Expected malformedResponse")
        } catch {
            XCTAssertEqual(error as? AIError, .malformedResponse)
        }
        XCTAssertEqual(config.usageEvents.first?.success, false)
        XCTAssertEqual(config.usageEvents.first?.errorMessage, "malformed_response")
    }

    func testRateLimitedMapsTo429() async {
        let config = makeConfig(withKey: true)
        let service = GeminiService(config: config, http: http(status: 429, json: [:]))
        do {
            _ = try await service.generate(feature: .foodParsing, userText: "eggs", schema: schema, decoding: TestFood.self)
            XCTFail("Expected rateLimited")
        } catch {
            XCTAssertEqual(error as? AIError, .rateLimited)
        }
        XCTAssertEqual(config.usageEvents.first?.errorMessage, "rate_limited")
    }

    func testPolicyBlockedDetected() async {
        let config = makeConfig(withKey: true)
        let blocked: [String: Any] = ["promptFeedback": ["blockReason": "SAFETY"]]
        let service = GeminiService(config: config, http: http(status: 200, json: blocked))
        do {
            _ = try await service.generate(feature: .acneAssessment, userText: "x", schema: schema, decoding: TestFood.self)
            XCTFail("Expected policyBlocked")
        } catch {
            XCTAssertEqual(error as? AIError, .policyBlocked)
        }
        XCTAssertEqual(config.usageEvents.first?.errorMessage, "policy_blocked")
    }

    func testModelUnavailableOn404() async {
        let config = makeConfig(withKey: true)
        let service = GeminiService(config: config, http: http(status: 404, json: [:]))
        do {
            _ = try await service.generate(feature: .foodParsing, userText: "eggs", schema: schema, decoding: TestFood.self)
            XCTFail("Expected modelUnavailable")
        } catch {
            XCTAssertEqual(error as? AIError, .modelUnavailable)
        }
    }
}
