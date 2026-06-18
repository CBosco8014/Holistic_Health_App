import XCTest
@testable import HolisticHealth

@MainActor
final class MealLogStoreTests: XCTestCase {

    private func makeStore() -> MealLogStore {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return MealLogStore(persistence: FileDataStore(baseDirectory: dir), fileName: "log.json")
    }

    private func entry(_ name: String, protein: Double, daysAgo: Int = 0) -> MealLogEntry {
        MealLogEntry(
            foodName: name,
            servingDescription: "1 serving",
            macros: MacroNutrients(proteinGrams: protein, carbGrams: 10, fatGrams: 5, calories: 120),
            loggedAt: Date().addingTimeInterval(Double(-daysAgo) * 86_400)
        )
    }

    func testDailyTotalsSumOnlyToday() {
        let store = makeStore()
        store.add(entry("Eggs", protein: 12))
        store.add(entry("Yogurt", protein: 18))
        store.add(entry("Old food", protein: 99, daysAgo: 2))

        let totals = store.dailyTotals()
        XCTAssertEqual(totals.proteinGrams, 30, accuracy: 0.001)
        XCTAssertEqual(totals.carbGrams, 20, accuracy: 0.001)
        XCTAssertEqual(store.entries().count, 2, "Only today's entries counted")
    }

    func testRemoveAndPersist() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store1 = MealLogStore(persistence: FileDataStore(baseDirectory: dir), fileName: "log.json")
        let e = entry("Eggs", protein: 12)
        store1.add(e)
        store1.add(entry("Oats", protein: 6))
        store1.remove(e)

        let store2 = MealLogStore(persistence: FileDataStore(baseDirectory: dir), fileName: "log.json")
        XCTAssertEqual(store2.entries.count, 1)
        XCTAssertEqual(store2.entries.first?.foodName, "Oats")
    }
}
