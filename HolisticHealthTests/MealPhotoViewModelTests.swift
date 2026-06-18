import XCTest
@testable import HolisticHealth

@MainActor
final class MealPhotoViewModelTests: XCTestCase {

    private func makeStores() -> (MacroLibraryStore, MealLogStore) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fs = FileDataStore(baseDirectory: dir)
        return (MacroLibraryStore(persistence: fs, fileName: "lib.json"),
                MealLogStore(persistence: fs, fileName: "log.json"))
    }

    private let meal = ParsedMealEstimate(items: [
        ParsedFoodEstimate(name: "Salmon fillet", servingDescription: "150 g",
                           proteinGrams: 34, carbGrams: 0, fatGrams: 12, calories: 280,
                           confidence: 0.8, assumptions: "Baked"),
        ParsedFoodEstimate(name: "Brown rice", servingDescription: "1 cup",
                           proteinGrams: 5, carbGrams: 45, fatGrams: 2, calories: 220,
                           confidence: 0.7, assumptions: nil)
    ])

    func testAnalyzeProducesEditableItems() async {
        let (lib, log) = makeStores()
        let vm = MealPhotoViewModel(library: lib, mealLog: log, analyzer: { _ in self.meal })
        vm.setImage(Data([0x01]))
        await vm.analyze()
        XCTAssertEqual(vm.phase, .review)
        XCTAssertEqual(vm.items.count, 2)
        XCTAssertEqual(vm.items.first?.name, "Salmon fillet")
        XCTAssertTrue(lib.records.isEmpty, "Nothing saved before confirm")
        XCTAssertTrue(log.entries.isEmpty)
    }

    func testConfirmSavesOnlyIncludedItems() async {
        let (lib, log) = makeStores()
        let vm = MealPhotoViewModel(library: lib, mealLog: log, analyzer: { _ in self.meal })
        vm.setImage(Data([0x01]))
        await vm.analyze()
        vm.items[1].include = false   // drop the rice

        let saved = vm.confirm()
        XCTAssertEqual(saved, 1)
        XCTAssertEqual(log.entries.count, 1)
        XCTAssertEqual(log.entries.first?.foodName, "Salmon fillet")
        XCTAssertEqual(log.entries.first?.source, .geminiPhoto)
        XCTAssertEqual(lib.records.count, 1)
        XCTAssertEqual(vm.phase, .capture, "Resets after confirm")
    }

    func testEditsArePreservedOnConfirm() async throws {
        let (lib, log) = makeStores()
        let vm = MealPhotoViewModel(library: lib, mealLog: log, analyzer: { _ in self.meal })
        vm.setImage(Data([0x01]))
        await vm.analyze()
        vm.items[0].protein = "40"
        vm.items[0].category = .dinner
        vm.items[1].include = false
        vm.confirm()
        let entry = try XCTUnwrap(log.entries.first)
        XCTAssertEqual(entry.macros.proteinGrams, 40, accuracy: 0.001)
        XCTAssertEqual(entry.category, .dinner)
    }

    func testAnalyzeErrorSurfacesMessage() async {
        let (lib, log) = makeStores()
        let vm = MealPhotoViewModel(library: lib, mealLog: log, analyzer: { _ in throw AIError.rateLimited })
        vm.setImage(Data([0x01]))
        await vm.analyze()
        XCTAssertEqual(vm.phase, .capture)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testEmptyResultShowsGuidance() async {
        let (lib, log) = makeStores()
        let vm = MealPhotoViewModel(library: lib, mealLog: log, analyzer: { _ in ParsedMealEstimate(items: []) })
        vm.setImage(Data([0x01]))
        await vm.analyze()
        XCTAssertEqual(vm.phase, .capture)
        XCTAssertNotNil(vm.errorMessage)
    }
}
