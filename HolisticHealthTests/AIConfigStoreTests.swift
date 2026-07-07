import XCTest
@testable import HolisticHealth

@MainActor
final class AIConfigStoreTests: XCTestCase {

    private func makeStore(account: String) -> AIConfigStore {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return AIConfigStore(persistence: FileDataStore(baseDirectory: dir), keychainAccount: account)
    }

    func testEstimateCostUsesPricing() {
        let cost = AIConfigStore.estimateCost(model: .flash, promptTokens: 1_000_000, completionTokens: 1_000_000)
        XCTAssertEqual(cost ?? -1, 0.30 + 2.50, accuracy: 0.0001)
        XCTAssertNil(AIConfigStore.estimateCost(model: .flash, promptTokens: nil, completionTokens: nil))
    }

    func testModelSelectionPersists() {
        let account = "test_model_\(UUID().uuidString)"
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store1 = AIConfigStore(persistence: FileDataStore(baseDirectory: dir), keychainAccount: account)
        store1.selectModel(.pro)
        let store2 = AIConfigStore(persistence: FileDataStore(baseDirectory: dir), keychainAccount: account)
        XCTAssertEqual(store2.selectedModel, .pro)
    }

    func testCostSummaryBuckets() {
        let store = makeStore(account: "test_cost_\(UUID().uuidString)")
        let now = Date()
        func event(daysAgo: Int, cost: Double) -> APIUsageEvent {
            APIUsageEvent(feature: .foodParsing, model: GeminiModel.flash.rawValue,
                          timestamp: now.addingTimeInterval(Double(-daysAgo) * 86_400),
                          success: true, estimatedCostUSD: cost)
        }
        store.record(event(daysAgo: 0, cost: 0.10))
        store.record(event(daysAgo: 3, cost: 0.20))
        store.record(event(daysAgo: 10, cost: 0.50))

        let s = store.costSummary(now: now)
        XCTAssertEqual(s.total, 0.80, accuracy: 0.0001)
        XCTAssertEqual(s.today, 0.10, accuracy: 0.0001)
        XCTAssertEqual(s.last7Days, 0.30, accuracy: 0.0001) // today + 3 days ago
        XCTAssertEqual(s.eventCount, 3)
        XCTAssertEqual(s.averagePerActiveDay, 0.80 / 3.0, accuracy: 0.0001)
    }

    func testKeychainSaveReadClearThroughStore() {
        let account = "test_key_\(UUID().uuidString)"
        let store = makeStore(account: account)
        XCTAssertFalse(store.hasAPIKey)
        XCTAssertTrue(store.saveAPIKey("  secret-123  "))
        XCTAssertTrue(store.hasAPIKey)
        XCTAssertEqual(store.apiKey(), "secret-123") // trimmed
        store.clearAPIKey()
        XCTAssertFalse(store.hasAPIKey)
        XCTAssertNil(store.apiKey())
    }

    func testEmptyKeyRejected() {
        let store = makeStore(account: "test_empty_\(UUID().uuidString)")
        XCTAssertFalse(store.saveAPIKey("   "))
        XCTAssertFalse(store.hasAPIKey)
    }
}
