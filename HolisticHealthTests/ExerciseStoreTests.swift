import XCTest
@testable import HolisticHealth

@MainActor
final class ExerciseStoreTests: XCTestCase {

    private func makeStore(dir: URL? = nil) -> (ExerciseStore, URL) {
        let directory = dir ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return (ExerciseStore(persistence: FileDataStore(baseDirectory: directory), fileName: "ex.json"), directory)
    }

    func testAddAndDailySummary() {
        let (store, _) = makeStore()
        store.add(ExerciseSession(category: .weightlifting, intensity: .high, durationMinutes: 30))
        store.add(ExerciseSession(category: .sprintBurst, activity: .rowing, durationMinutes: 15))
        store.add(ExerciseSession(category: .weightlifting, intensity: .low, durationMinutes: 20,
                                  timestamp: Date().addingTimeInterval(-3 * 86_400)))

        XCTAssertEqual(store.sessions().count, 2, "Only today's sessions")
        XCTAssertEqual(store.totalMinutes(), 45)
    }

    func testRemove() {
        let (store, _) = makeStore()
        let s = ExerciseSession(category: .sprintBurst, activity: .boxing, durationMinutes: 10)
        store.add(s)
        store.remove(s)
        XCTAssertTrue(store.sessions.isEmpty)
    }

    func testMultipleSessionsPerDayAndPersist() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let (store1, _) = makeStore(dir: dir)
        store1.add(ExerciseSession(category: .weightlifting, intensity: .medium, durationMinutes: 25))
        store1.add(ExerciseSession(category: .sprintBurst, activity: .running, durationMinutes: 20))
        let (store2, _) = makeStore(dir: dir)
        XCTAssertEqual(store2.sessions(on: Date()).count, 2)
        XCTAssertEqual(store2.totalMinutes(), 45)
    }
}
