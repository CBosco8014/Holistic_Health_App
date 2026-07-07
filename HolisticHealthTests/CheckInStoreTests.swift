import XCTest
@testable import HolisticHealth

@MainActor
final class CheckInStoreTests: XCTestCase {

    private func makeStore(dir: URL? = nil) -> (CheckInStore, URL) {
        let directory = dir ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return (CheckInStore(persistence: FileDataStore(baseDirectory: directory), fileName: "ci.json"), directory)
    }

    func testSaveUpdatesNotDuplicates() {
        let (store, _) = makeStore()
        var c = HormoneSkinCheckIn(stress: 3)
        store.save(c)
        XCTAssertEqual(store.checkIns.count, 1)
        c.stress = 5
        store.save(c)
        XCTAssertEqual(store.checkIns.count, 1)
        XCTAssertEqual(store.latest?.stress, 5)
    }

    func testTodaysAndRecentOrdering() {
        let (store, _) = makeStore()
        store.save(HormoneSkinCheckIn(date: Date().addingTimeInterval(-3 * 86_400), mood: 2))
        store.save(HormoneSkinCheckIn(date: Date(), mood: 4))
        XCTAssertNotNil(store.todays())
        XCTAssertEqual(store.todays()?.mood, 4)
        XCTAssertEqual(store.recent(10).first?.mood, 4)
    }

    func testPersistAcrossReload() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let (store1, _) = makeStore(dir: dir)
        store1.save(HormoneSkinCheckIn(acneSeverity: 3, acneLocations: ["Jaw"], customSymptoms: ["headache"]))
        let (store2, _) = makeStore(dir: dir)
        XCTAssertEqual(store2.checkIns.count, 1)
        XCTAssertEqual(store2.latest?.acneLocations, ["Jaw"])
        XCTAssertEqual(store2.latest?.customSymptoms, ["headache"])
    }

    func testDelete() {
        let (store, _) = makeStore()
        let c = HormoneSkinCheckIn(mood: 3)
        store.save(c)
        store.delete(c)
        XCTAssertTrue(store.checkIns.isEmpty)
    }
}
