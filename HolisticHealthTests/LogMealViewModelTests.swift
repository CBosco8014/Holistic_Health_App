import XCTest
@testable import HolisticHealth

@MainActor
final class LogMealViewModelTests: XCTestCase {

    private func makeStores() -> (MacroLibraryStore, MealLogStore) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fs = FileDataStore(baseDirectory: dir)
        return (MacroLibraryStore(persistence: fs, fileName: "lib.json"),
                MealLogStore(persistence: fs, fileName: "log.json"))
    }

    private let sampleEstimate = ParsedFoodEstimate(
        name: "Avocado toast", servingDescription: "1 slice",
        proteinGrams: 8, carbGrams: 24, fatGrams: 14, calories: 260,
        confidence: 0.7, assumptions: "Sourdough, half an avocado"
    )

    func testLibraryFirstReturnsKnownMatch() {
        let (lib, log) = makeStores()
        lib.upsert(MacroLibraryRecord(canonicalName: "Greek yogurt", servingDescription: "1 cup",
                                      macros: MacroNutrients(proteinGrams: 20, carbGrams: 9, fatGrams: 1, calories: 130)))
        let vm = LogMealViewModel(library: lib, mealLog: log, estimator: { _ in
            XCTFail("Estimator must not be called for a known food")
            throw AIError.missingAPIKey
        })
        vm.query = "greek"
        vm.refreshMatches()
        XCTAssertTrue(vm.hasMatches)
        XCTAssertEqual(vm.matches.first?.canonicalName, "Greek yogurt")
    }

    func testUnknownFoodFallbackRequiresConfirmationBeforeSaving() async {
        let (lib, log) = makeStores()
        let vm = LogMealViewModel(library: lib, mealLog: log, estimator: { _ in self.sampleEstimate })
        vm.query = "avocado toast"
        vm.refreshMatches()
        XCTAssertFalse(vm.hasMatches)

        await vm.requestEstimate()
        XCTAssertEqual(vm.step, .confirmEstimate)
        XCTAssertEqual(vm.draftName, "Avocado toast")
        // Nothing saved yet — confirmation required.
        XCTAssertTrue(lib.records.isEmpty)
        XCTAssertTrue(log.entries.isEmpty)
    }

    func testConfirmEstimateSavesLibraryAndLogAndRecalculatesTotals() async {
        let (lib, log) = makeStores()
        let vm = LogMealViewModel(library: lib, mealLog: log, estimator: { _ in self.sampleEstimate })
        vm.query = "avocado toast"
        await vm.requestEstimate()
        vm.confirmAndLog()

        XCTAssertEqual(lib.records.count, 1)
        XCTAssertEqual(lib.records.first?.source, .geminiText)
        XCTAssertEqual(log.entries.count, 1)
        XCTAssertEqual(log.dailyTotals().proteinGrams, 8, accuracy: 0.001)
        XCTAssertEqual(vm.step, .search, "Resets after logging")
    }

    func testKnownFoodLogsWithoutDuplicatingLibrary() {
        let (lib, log) = makeStores()
        let record = MacroLibraryRecord(canonicalName: "Eggs", servingDescription: "2 eggs",
                                        macros: MacroNutrients(proteinGrams: 12, carbGrams: 1, fatGrams: 10, calories: 140))
        lib.upsert(record)
        let vm = LogMealViewModel(library: lib, mealLog: log, estimator: { _ in self.sampleEstimate })
        vm.selectKnown(record)
        XCTAssertEqual(vm.step, .confirmKnown)
        vm.confirmAndLog()

        XCTAssertEqual(lib.records.count, 1, "Known food should not create a new library record")
        XCTAssertEqual(log.entries.count, 1)
        XCTAssertEqual(log.entries.first?.libraryRecordID, record.id)
        XCTAssertEqual(log.dailyTotals().proteinGrams, 12, accuracy: 0.001)
    }

    func testEstimatorErrorSurfacesMessage() async {
        let (lib, log) = makeStores()
        let vm = LogMealViewModel(library: lib, mealLog: log, estimator: { _ in throw AIError.missingAPIKey })
        vm.query = "mystery dish"
        await vm.requestEstimate()
        XCTAssertEqual(vm.step, .search)
        XCTAssertNotNil(vm.errorMessage)
    }
}
