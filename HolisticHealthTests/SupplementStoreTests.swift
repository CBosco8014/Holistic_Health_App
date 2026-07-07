import XCTest
@testable import HolisticHealth

@MainActor
final class SupplementStoreTests: XCTestCase {

    private func makeStore(dir: URL? = nil) -> (SupplementStore, URL) {
        let directory = dir ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = SupplementStore(persistence: FileDataStore(baseDirectory: directory),
                                    supplementsFile: "s.json", logsFile: "sl.json")
        return (store, directory)
    }

    func testSaveAndUpdate() {
        let (store, _) = makeStore()
        var s = Supplement(name: "Magnesium")
        store.save(s)
        XCTAssertEqual(store.supplements.count, 1)
        s.adherence = .paused
        store.save(s)
        XCTAssertEqual(store.supplements.count, 1)
        XCTAssertEqual(store.supplements.first?.adherence, .paused)
    }

    func testAdherenceToggleAndQuery() {
        let (store, _) = makeStore()
        let s = Supplement(name: "Zinc")
        store.save(s)
        XCTAssertFalse(store.isTakenToday(s.id))
        store.setTakenToday(s.id, taken: true)
        XCTAssertTrue(store.isTakenToday(s.id))
        store.setTakenToday(s.id, taken: false)
        XCTAssertFalse(store.isTakenToday(s.id))
    }

    func testDeleteRemovesSupplementAndLogs() {
        let (store, _) = makeStore()
        let s = Supplement(name: "Omega-3")
        store.save(s)
        store.setTakenToday(s.id, taken: true)
        store.delete(s)
        XCTAssertTrue(store.supplements.isEmpty)
        XCTAssertTrue(store.logs.isEmpty)
    }

    func testPersistAcrossReload() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let (store1, _) = makeStore(dir: dir)
        let s = Supplement(name: "Vitamin D", schedule: "Daily", timing: "Morning")
        store1.save(s)
        store1.setTakenToday(s.id, taken: true)
        let (store2, _) = makeStore(dir: dir)
        XCTAssertEqual(store2.supplements.first?.name, "Vitamin D")
        XCTAssertTrue(store2.isTakenToday(s.id))
    }
}
