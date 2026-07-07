import XCTest
@testable import HolisticHealth

@MainActor
final class MacroLibraryStoreTests: XCTestCase {

    private func makeStore() -> MacroLibraryStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let fileStore = FileDataStore(baseDirectory: dir)
        return MacroLibraryStore(persistence: fileStore, fileName: "lib.json")
    }

    private func record(_ name: String, protein: Double = 10) -> MacroLibraryRecord {
        MacroLibraryRecord(
            canonicalName: name,
            servingDescription: "1 serving",
            macros: MacroNutrients(proteinGrams: protein, carbGrams: 5, fatGrams: 2, calories: 80)
        )
    }

    func testUpsertAddsAndUpdates() {
        let store = makeStore()
        var r = record("Eggs")
        store.upsert(r)
        XCTAssertEqual(store.records.count, 1)

        r.macros.proteinGrams = 18
        store.upsert(r)
        XCTAssertEqual(store.records.count, 1, "Same id should update, not duplicate")
        XCTAssertEqual(store.records.first?.macros.proteinGrams, 18)
    }

    func testDeleteAndClear() {
        let store = makeStore()
        let r = record("Eggs")
        store.upsert(r)
        store.delete(r)
        XCTAssertTrue(store.records.isEmpty)

        store.upsert(record("A"))
        store.upsert(record("B"))
        store.clear()
        XCTAssertTrue(store.records.isEmpty)
    }

    func testPersistenceAcrossReload() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store1 = MacroLibraryStore(persistence: FileDataStore(baseDirectory: dir), fileName: "lib.json")
        store1.upsert(record("Salmon", protein: 22))

        let store2 = MacroLibraryStore(persistence: FileDataStore(baseDirectory: dir), fileName: "lib.json")
        XCTAssertEqual(store2.records.count, 1)
        XCTAssertEqual(store2.records.first?.canonicalName, "Salmon")
    }

    func testSearchRanksCanonicalBeforeAlias() {
        let store = makeStore()
        store.upsert(MacroLibraryRecord(canonicalName: "Chicken breast", servingDescription: "100 g",
                                        macros: .zero))
        store.upsert(MacroLibraryRecord(canonicalName: "Greek yogurt", aliases: ["chicken-flavored snack"],
                                        servingDescription: "1 cup", macros: .zero))
        let results = store.search("chicken")
        XCTAssertEqual(results.first?.canonicalName, "Chicken breast")
    }

    func testExportImportRoundTrip() throws {
        let store = makeStore()
        store.upsert(record("Eggs"))
        store.upsert(record("Oats"))
        let data = try store.exportData()

        let other = makeStore()
        let result = try other.importLibrary(from: data, strategy: .replace)
        XCTAssertEqual(result.total, 2)
        XCTAssertEqual(Set(other.records.map(\.canonicalName)), ["Eggs", "Oats"])
    }

    func testMergeDoesNotDuplicateByName() throws {
        let store = makeStore()
        store.upsert(record("Eggs", protein: 6))
        // Import a differently-id'd record with the same name -> should update.
        let incoming = [record("eggs", protein: 12)]
        let data = try JSONCoding.encoder.encode(incoming)
        let result = try store.importLibrary(from: data, strategy: .merge)
        XCTAssertEqual(result.added, 0)
        XCTAssertEqual(result.updated, 1)
        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records.first?.macros.proteinGrams, 12)
    }

    func testMergeAddsNew() throws {
        let store = makeStore()
        store.upsert(record("Eggs"))
        let incoming = [record("Tofu")]
        let data = try JSONCoding.encoder.encode(incoming)
        let result = try store.importLibrary(from: data, strategy: .merge)
        XCTAssertEqual(result.added, 1)
        XCTAssertEqual(store.records.count, 2)
    }
}
